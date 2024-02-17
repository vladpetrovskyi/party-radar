package main

import (
	"context"
	"database/sql"
	"errors"
	firebase "firebase.google.com/go"
	"flag"
	"fmt"
	"github.com/casbin/casbin/v2"
	_ "github.com/lib/pq"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/api/option"
	"net/http"
	"os/signal"
	database "party-time/db"
	sqlc "party-time/db"
	"party-time/rbac"
	"syscall"
	"time"
)

const version = "1.0.0"

type config struct {
	port int
	env  string
}

type application struct {
	cfg         config
	log         *zerolog.Logger
	ctx         context.Context
	enforcer    *casbin.Enforcer
	firebaseApp *firebase.App
	db          *sql.DB
	q           *sqlc.Queries
}

func main() {
	var cfg config

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	flag.IntVar(&cfg.port, "port", 8080, "API server port")
	flag.StringVar(&cfg.env, "env", "local", "Environment (local|dev|prod)")
	flag.Parse()

	var logger = log.Logger

	db, queries := database.Init(ctx, &logger)

	var app = application{
		cfg:      cfg,
		log:      &logger,
		ctx:      ctx,
		db:       db,
		q:        queries,
		enforcer: rbac.Init(db, &logger),
	}

	var err error
	opt := option.WithCredentialsFile("serviceAccountKey.json")
	app.firebaseApp, err = firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		panic(fmt.Errorf("error initializing firebaseApp: %v", err))
	}

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.port),
		IdleTimeout:  time.Minute,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		Handler:      app.routes(),
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal().AnErr("listen: %s\n", err).Ctx(ctx)
		}
	}()

	app.log.Info().Msg("Server setup finished!")

	<-ctx.Done()

	stop()
	app.log.Warn().Msg("shutting down gracefully, press Ctrl+C again to force")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Error().AnErr("Server forced to shutdown: ", err)
	}

	app.log.Info().Msg("Server exiting")
}
