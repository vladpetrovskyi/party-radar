package api

import (
	"context"
	"database/sql"
	firebase "firebase.google.com/go"
	"fmt"
	sqladapter "github.com/Blank-Xu/sql-adapter"
	"github.com/casbin/casbin/v2"
	"github.com/gin-contrib/logger"
	"github.com/gin-gonic/gin"
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

	return &app
}

func (app *Application) GetRouter() *gin.Engine {
	return app.router
}

func (app *Application) setupRoutes() {
	app.log.Info().Msg("Setting up router...")

	router := gin.New()
	router.Use(logger.SetLogger(logger.WithLogger(func(context *gin.Context, z zerolog.Logger) zerolog.Logger {
		return *app.log
	})))

	v1 := router.Group("/api/v1")

	v1.GET("/healthcheck", app.healthcheckHandler)

	imageGroup := v1.Group("/image")
	imageGroup.HEAD("/:id", app.authorizeViaFirebase("data", "read"), app.checkImageExists)
	imageGroup.GET("/:id", app.authorizeViaFirebase("data", "read"), app.getImage)
	imageGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createImage)
	imageGroup.PUT("/:id", app.authorizeViaFirebase("data", "write"), app.updateImage)

	userGroup := v1.Group("/user")
	userGroup.POST("/registration", app.register)
	userGroup.HEAD("/:username", app.authorizeViaFirebase("data", "read"), app.getUserByUsername)
	userGroup.GET("/:username", app.authorizeViaFirebase("data", "read"), app.getUserByUsername)
	userGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getUserByUID)
	userGroup.DELETE("", app.authorizeViaFirebase("data", "write"), app.deleteUser)
	userGroup.PUT("/username", app.authorizeViaFirebase("data", "write"), app.updateUsername)
	userGroup.PUT("/root-location/:id", app.authorizeViaFirebase("data", "write"), app.updateUserRootLocation)
	userGroup.DELETE("/location", app.authorizeViaFirebase("data", "write"), app.deleteUserLocation)

	locationGroup := v1.Group("/location")
	locationGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getLocations)
	locationGroup.GET("/:id", app.authorizeViaFirebase("data", "read"), app.getLocation)
	locationGroup.GET("/:id/user/count", app.authorizeViaFirebase("data", "read"), app.getLocationUserCount)

	postGroup := v1.Group("/post")
	postGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getPosts)
	postGroup.GET("/feed", app.authorizeViaFirebase("data", "read"), app.getFeed)
	postGroup.GET("/count", app.authorizeViaFirebase("data", "read"), app.getUserPostsCount)
	postGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createPost)
	postGroup.PUT("/:id/view", app.authorizeViaFirebase("data", "write"), app.increaseViewsByOne)
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
