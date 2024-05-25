package api

import (
	"context"
	"database/sql"
	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"fmt"
	sqladapter "github.com/Blank-Xu/sql-adapter"
	"github.com/casbin/casbin/v2"
	"github.com/gin-contrib/logger"
	"github.com/gin-gonic/gin"
	"github.com/robfig/cron/v3"
	"github.com/rs/zerolog"
	"party-time/config"
	sqlc "party-time/db"
)

type Application struct {
	c      *config.Conf
	log    *zerolog.Logger
	ctx    context.Context
	n4cer  *casbin.Enforcer
	fb     *firebase.App
	db     *sql.DB
	q      *sqlc.Queries
	router *gin.Engine
	msg    *messaging.Client
}

func New(c *config.Conf,
	log *zerolog.Logger,
	ctx context.Context,
	fb *firebase.App,
	db *sql.DB) *Application {

	app := Application{
		c:   c,
		log: log,
		ctx: ctx,
		fb:  fb,
		db:  db,
		q:   sqlc.New(db),
	}

	app.setupRBAC()
	app.setupRoutes()
	app.setupAutoLogout()

	msg, err := fb.Messaging(ctx)
	if err != nil {
		panic(fmt.Errorf("error initializing Firebase Messaging: %v", err))
	}
	app.msg = msg

	return &app
}

func (app *Application) GetRouter() *gin.Engine {
	return app.router
}

func (app *Application) setupRoutes() {
	app.log.Info().Msg("Setting up router...")

	if app.c.Server.Environment == "prod" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(logger.SetLogger(logger.WithLogger(func(context *gin.Context, z zerolog.Logger) zerolog.Logger {
		return *app.log
	})))

	api := router.Group("/api")

	v1 := api.Group("/v1")
	v2 := api.Group("/v2")

	v1.GET("/healthcheck", app.healthcheckHandler)

	imageGroup := v1.Group("/image")
	imageGroup.HEAD("/:id", app.authorizeViaFirebase("data", "read"), app.checkImageExists)
	imageGroup.GET("/:id", app.authorizeViaFirebase("data", "read"), app.getImage)
	imageGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createImage)
	imageGroup.PUT("/:id", app.authorizeViaFirebase("data", "write"), app.updateImage)

	userGroupV1 := v1.Group("/user")
	userGroupV1.POST("/registration", app.register)
	userGroupV1.HEAD("/:username", app.authorizeViaFirebase("data", "read"), app.getUserByUsername)
	userGroupV1.GET("/:username", app.authorizeViaFirebase("data", "read"), app.getUserByUsername)
	userGroupV1.GET("", app.authorizeViaFirebase("data", "read"), app.getUserByUID)
	userGroupV1.DELETE("", app.authorizeViaFirebase("data", "write"), app.deleteUser)
	userGroupV1.PUT("/username", app.authorizeViaFirebase("data", "write"), app.updateUsername)
	userGroupV1.PUT("/root-location/:id", app.authorizeViaFirebase("data", "write"), app.updateUserRootLocation)
	userGroupV1.DELETE("/location", app.authorizeViaFirebase("data", "write"), app.deleteUserLocation)
	userGroupV1.PATCH("/fcm-token", app.authorizeViaFirebase("data", "write"), app.updateUserFCMToken)
	userGroupV1.GET("/topic", app.authorizeViaFirebase("data", "write"), app.getUserTopics)
	userGroupV1.POST("/topic", app.authorizeViaFirebase("data", "write"), app.subscribeToTopic)
	userGroupV1.DELETE("/topic", app.authorizeViaFirebase("data", "write"), app.unsubscribeFromTopic)

	userGroupV2 := v2.Group("/user")
	userGroupV2.HEAD("", app.authorizeViaFirebase("data", "read"), app.getUser)
	userGroupV2.GET("", app.authorizeViaFirebase("data", "read"), app.getUser)

	locationGroup := v1.Group("/location")
	locationGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getLocations)
	locationGroup.GET("/:id", app.authorizeViaFirebase("data", "read"), app.getLocation)
	locationGroup.GET("/:id/user/count", app.authorizeViaFirebase("data", "read"), app.getLocationUserCount)
	locationGroup.GET("/:id/availability", app.authorizeViaFirebase("data", "read"), app.getLocationAvailability)
	locationGroup.PATCH("/:id/availability", app.authorizeViaFirebase("data", "read"), app.updateLocationAvailability)

	postGroup := v1.Group("/post")
	postGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getPosts)
	postGroup.GET("/feed", app.authorizeViaFirebase("data", "read"), app.getFeed)
	postGroup.GET("/count", app.authorizeViaFirebase("data", "read"), app.getUserPostsCount)
	postGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createPost)
	postGroup.PUT("/:id/view", app.authorizeViaFirebase("data", "write"), app.increaseViewsByOne)
	postGroup.GET("/:id/view", app.authorizeViaFirebase("data", "read"), app.getPostViewsCount)
	postGroup.DELETE("/:id", app.authorizeViaFirebase("data", "write"), app.deletePost)

	friendshipGroup := v1.Group("/friendship")
	friendshipGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getFriendships)
	friendshipGroup.GET("/count", app.authorizeViaFirebase("data", "read"), app.getFriendshipsCount)
	friendshipGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createFriendshipRequest)
	friendshipGroup.PUT("/:id", app.authorizeViaFirebase("data", "write"), app.updateFriendship)
	friendshipGroup.DELETE("/:id", app.authorizeViaFirebase("data", "write"), app.deleteFriendship)

	app.log.Info().Msg("Router setup finished!")

	app.router = router
}

func (app *Application) setupRBAC() {
	app.log.Info().Msg("Setting up RBAC...")

	if app.db == nil {
		panic(fmt.Sprint("RBAC setup should be after DB initialisation!"))
	}

	var (
		adapter *sqladapter.Adapter
		err     error
	)

	if adapter, err = sqladapter.NewAdapter(app.db, "postgres", ""); err != nil {
		panic(fmt.Errorf("failed to create rbac adapter: %w", err))
	}

	enforcer, err := casbin.NewEnforcer("config/model.conf", adapter)
	if err != nil {
		panic(fmt.Errorf("failed to create rbac enforcer: %w", err))
	}

	if err = enforcer.LoadPolicy(); err != nil {
		panic(fmt.Errorf("failed to load policy from DB: %w", err))
	}

	if _, err = enforcer.AddPolicies([][]string{
		{"guest", "data", "read"}, {"user", "data", "write"}, {"admin", "data", "delete"},
	}); err != nil {
		panic(fmt.Errorf("failed to add policies to DB: %w", err))
	}

	if _, err = enforcer.AddGroupingPolicies([][]string{
		{"user", "guest"}, {"admin", "user"},
	}); err != nil {
		panic(fmt.Errorf("failed to add policies to DB: %w", err))
	}

	app.log.Info().Msg("RBAC set up finished!")

	app.n4cer = enforcer
}

func (app *Application) setupAutoLogout() {
	app.log.Info().Msg("Creating a scheduled auto logout task...")

	c := cron.New()
	_, err := c.AddFunc("0 0 * * 3", func() {
		app.log.Info().Msg("Starting scheduled auto logout task...")

		rootLocationType := "root"
		rootLocations, err := app.q.GetLocationsByElementType(app.ctx, &rootLocationType)
		if err != nil {
			app.log.Err(err).Msg("Could not get root locations by element type while executing scheduled auto logout task")
			return
		}

		postTypeId, err := app.q.GetPostTypeId(app.ctx, "end")
		if err != nil {
			app.log.Err(err).Msgf("Could not get post type ID while executing scheduled auto logout task")
			return
		}

		tx, err := app.db.BeginTx(app.ctx, nil)
		if err != nil {
			app.log.Err(err).Msg("Could not create a transaction while executing scheduled auto logout task")
			return
		}
		defer tx.Rollback()
		withTx := app.q.WithTx(tx)

		for _, location := range rootLocations {
			users, err := app.q.GetUsersByRootLocationID(app.ctx, &location.ID)
			if err != nil {
				app.log.Err(err).Msg("Could not get users by root location ID while executing scheduled auto logout task")
				return
			}

			for _, user := range users {
				if err := withTx.UpdateUserLocation(app.ctx, sqlc.UpdateUserLocationParams{
					ID:                user.ID,
					CurrentLocationID: nil,
				}); err != nil {
					app.log.Err(err).Msgf("Could not update location of user with ID = %v while executing scheduled auto logout task", user.ID)
					return
				}

				if err = withTx.UpdateUserRootLocation(app.ctx, sqlc.UpdateUserRootLocationParams{
					ID:                    user.ID,
					CurrentRootLocationID: nil,
				}); err != nil {
					app.log.Err(err).Msgf("Could not update root location of user with ID = %v while executing scheduled auto logout task", user.ID)
					return
				}

				if err := withTx.CreatePost(app.ctx, sqlc.CreatePostParams{
					UserID:     user.ID,
					LocationID: location.ID,
					PostTypeID: postTypeId,
				}); err != nil {
					app.log.Err(err).Msgf("Could not create logout post for user with ID = %v while executing scheduled auto logout task", user.ID)
					return
				}
			}
		}

		if err = tx.Commit(); err != nil {
			app.log.Err(err).Msg("Could not commit a transaction while executing scheduled auto logout task")
			return
		}

		app.log.Info().Msg("Scheduled auto logout task successfully completed!")
	})
	if err != nil {
		app.log.Err(err).Msg("Could not create a scheduled auto logout task")
		return
	}

	c.Start()

	app.log.Info().Msg("Auto logout task successfully created!")
}
