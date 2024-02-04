package main

import (
	"context"
	"database/sql"
	"embed"
	"errors"
	firebase "firebase.google.com/go"
	"fmt"
	sqladapter "github.com/Blank-Xu/sql-adapter"
	"github.com/casbin/casbin/v2"
	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
	"github.com/pressly/goose/v3"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/api/option"
	"io/fs"
	"net/http"
	"os"
	"os/signal"
	sqlc "party-time/db"
	"party-time/internal"
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"
)

var (
	//go:embed db/migrations/*.sql
	embedMigrations embed.FS

	//go:embed db/seeds/*.sql
	embedSeeds embed.FS

	//go:embed db/seeds/assets/*.png
	embedImages embed.FS
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.TimeOnly})

	var (
		err      error
		enforcer *casbin.Enforcer
	)

	db := initDB()
	queries := sqlc.New(db)

	applyMigrations(db)

	err = populateImages(ctx, queries)
	if err != nil {
		panic(fmt.Errorf("failed to populate images into DB: %w", err))
	}

	populateSeeds(db)

	if enforcer, err = initCasbin(db); err != nil {
		panic(fmt.Errorf("failed to add policies to DB: %w", err))
	}

	opt := option.WithCredentialsFile("serviceAccountKey.json")
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		panic(fmt.Errorf("error initializing app: %v", err))
	}

	router := gin.Default()
	setupRoutes(router, queries, db, ctx, enforcer, app)

	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal().AnErr("listen: %s\n", err).Ctx(ctx)
		}
	}()

	<-ctx.Done()

	stop()
	log.Warn().Msg("shutting down gracefully, press Ctrl+C again to force")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Error().AnErr("Server forced to shutdown: ", err)
	}

	log.Info().Msg("Server exiting")
}

func applyMigrations(db *sql.DB) {
	log.Info().Msg("Applying DB migrations...")
	goose.SetBaseFS(embedMigrations)
	if err := goose.SetDialect("postgres"); err != nil {
		panic(err)
	}
	if err := goose.Up(db, "db/migrations"); err != nil {
		panic(err)
	}
}

func populateImages(c context.Context, q *sqlc.Queries) error {
	dirName := "db/seeds/assets"
	dirFiles, err := fs.ReadDir(embedImages, dirName)
	if err != nil {
		return err
	}

	for _, f := range dirFiles {
		info, err := f.Info()
		if err != nil {
			return err
		}
		fileName := info.Name()
		imageId, err := strconv.ParseInt(strings.Split(fileName, "_")[0], 10, 64)
		if err != nil {
			return err
		}

		file, err := fs.ReadFile(embedImages, dirName+"/"+fileName)
		if err != nil {
			return err
		}

		err = q.UpsertImage(c, sqlc.UpsertImageParams{
			ID:       imageId,
			FileName: fileName,
			Content:  file,
		})
		if err != nil {
			return err
		}
	}

	err = q.ResetImageSequence(c)
	if err != nil {
		return err
	}

	return nil
}

func populateSeeds(db *sql.DB) {
	log.Info().Msg("Populating seeds into DB...")
	goose.SetBaseFS(embedSeeds)
	if err := goose.SetDialect("postgres"); err != nil {
		panic(err)
	}
	if err := goose.Up(db, "db/seeds"); err != nil {
		panic(err)
	}
}

func initCasbin(db *sql.DB) (enforcer *casbin.Enforcer, err error) {
	log.Info().Msg("Setting up Casbin auth...")

	var adapter *sqladapter.Adapter
	if adapter, err = sqladapter.NewAdapter(db, "postgres", ""); err != nil {
		panic(fmt.Errorf("failed to create casbin adapter: %w", err))
	}

	if enforcer, err = casbin.NewEnforcer("config/model.conf", adapter); err != nil {
		panic(fmt.Errorf("failed to create casbin enforcer: %w", err))
	}

	if err = enforcer.LoadPolicy(); err != nil {
		panic(fmt.Errorf("failed to load policy from DB: %w", err))
	}

	if _, err = enforcer.AddPolicies([][]string{
		{"guest", "data", "read"}, {"user", "data", "write"}, {"admin", "data", "delete"},
	}); err != nil {
		return nil, err
	}

	if _, err = enforcer.AddGroupingPolicies([][]string{
		{"user", "guest"}, {"admin", "user"},
	}); err != nil {
		return nil, err
	}

	return enforcer, nil
}

func setupRoutes(
	router *gin.Engine,
	queries *sqlc.Queries,
	database *sql.DB,
	ctx context.Context,
	enforcer *casbin.Enforcer,
	app *firebase.App,
) {
	log.Info().Msg("Setting up API routes...")

	v1 := router.Group("/api/v1")
	v1.GET("/health", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	authHandler := internal.AuthHandler{
		Ctx:      ctx,
		Enforcer: enforcer,
		App:      app,
	}

	imageHandler := &internal.ImageHandler{
		Queries: queries,
		DB:      database,
		Ctx:     ctx,
	}
	imageGroup := v1.Group("/image")
	imageGroup.GET("/:id", authHandler.AuthorizeViaFirebase("data", "read"), imageHandler.GetImage)
	imageGroup.POST("", authHandler.AuthorizeViaFirebase("data", "write"), imageHandler.CreateImage)
	imageGroup.PUT("/:id", authHandler.AuthorizeViaFirebase("data", "write"), imageHandler.UpdateImage)

	userHandler := &internal.UserHandler{
		Queries:  queries,
		DB:       database,
		Ctx:      ctx,
		Enforcer: enforcer,
	}
	userGroup := v1.Group("/user")
	userGroup.POST("/registration", userHandler.Register)
	userGroup.HEAD("/:username", authHandler.AuthorizeViaFirebase("data", "read"), userHandler.GetUserByUsername)
	userGroup.GET("/:username", authHandler.AuthorizeViaFirebase("data", "read"), userHandler.GetUserByUsername)
	userGroup.GET("", authHandler.AuthorizeViaFirebase("data", "read"), userHandler.GetUserByUID)
	userGroup.PUT("", authHandler.AuthorizeViaFirebase("data", "write"), userHandler.UpdateUser)
	userGroup.PUT("/username", authHandler.AuthorizeViaFirebase("data", "write"), userHandler.UpdateUsername)
	userGroup.PUT("/root-location/:id", authHandler.AuthorizeViaFirebase("data", "read"), userHandler.UpdateUserRootLocation)
	userGroup.DELETE("/location", authHandler.AuthorizeViaFirebase("data", "read"), userHandler.DeleteUserLocation)

	locationHandler := internal.LocationHandler{
		Queries: queries,
		DB:      database,
		Ctx:     ctx,
	}
	locationGroup := v1.Group("/location")
	locationGroup.GET("", authHandler.AuthorizeViaFirebase("data", "read"), locationHandler.GetLocations)
	locationGroup.GET("/:id", authHandler.AuthorizeViaFirebase("data", "read"), locationHandler.GetLocation)
	locationGroup.GET("/:id/user/count", authHandler.AuthorizeViaFirebase("data", "read"), locationHandler.GetLocationUserCount)

	postHandler := internal.PostHandler{
		Queries:         queries,
		DB:              database,
		Ctx:             ctx,
		LocationHandler: &locationHandler,
	}
	postGroup := v1.Group("/post")
	postGroup.GET("", authHandler.AuthorizeViaFirebase("data", "read"), postHandler.GetPosts)
	postGroup.GET("/feed", authHandler.AuthorizeViaFirebase("data", "read"), postHandler.GetFeed)
	postGroup.GET("/count", authHandler.AuthorizeViaFirebase("data", "read"), postHandler.GetUserPostsCount)
	postGroup.POST("", authHandler.AuthorizeViaFirebase("data", "read"), postHandler.CreatePost)

	friendshipHandler := internal.FriendshipHandler{
		Queries: queries,
		DB:      database,
		Ctx:     ctx,
	}
	friendshipGroup := v1.Group("/friendship")
	friendshipGroup.GET("", authHandler.AuthorizeViaFirebase("data", "read"), friendshipHandler.GetFriendships)
	friendshipGroup.GET("/count", authHandler.AuthorizeViaFirebase("data", "read"), friendshipHandler.GetFriendshipsCount)
	friendshipGroup.POST("", authHandler.AuthorizeViaFirebase("data", "write"), friendshipHandler.CreateFriendshipRequest)
	friendshipGroup.PUT("/:id", authHandler.AuthorizeViaFirebase("data", "write"), friendshipHandler.UpdateFriendship)
	friendshipGroup.DELETE("/:id", authHandler.AuthorizeViaFirebase("data", "write"), friendshipHandler.DeleteFriendship)
}

func initDB() (db *sql.DB) {
	log.Info().Msg("Connecting to DB...")

	var (
		host     = getEnvVar("DATASOURCE_HOST", getDefaultHost())
		port     = 5432
		user     = getEnvVar("POSTGRES_USER", "postgres")
		password = getEnvVar("POSTGRES_PASSWORD", "pass")
		dbname   = getEnvVar("POSTGRES_DB", "party-radar")
	)

	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)
	db, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		panic(fmt.Errorf("could not open DB connection: %w", err))
	}

	err = db.Ping()
	if err != nil {
		panic(fmt.Errorf("could not ping DB: %w", err))
	}

	return
}

func getEnvVar(varName string, defaultVal string) string {
	env, b := os.LookupEnv(varName)

	if b {
		return env
	} else {
		return defaultVal
	}
}

func getDefaultHost() string {
	if (runtime.GOOS == "darwin" || runtime.GOOS == "linux") && getEnvVar("IS_DOCKER_CONTAINER", "false") == "true" {
		return "docker.for.mac.localhost"
	}
	return "localhost"
}
