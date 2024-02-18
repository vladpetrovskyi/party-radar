package main

import (
	"context"
	"database/sql"
	"errors"
	firebase "firebase.google.com/go"
	"fmt"
	_ "github.com/lib/pq"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/api/option"
	"net/http"
	"os"
	"os/signal"
	"party-time/api"
	"party-time/config"
	"syscall"
	"time"
)

const dmtDBString = "host=%s port=%d user=%s password=%s dbname=%s sslmode=disable"

func main() {
	c := config.New()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	var logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.TimeOnly})

	logger.Info().Msg("Connecting to DB...")
	psqlInfo := fmt.Sprintf(dmtDBString, c.DB.Host, c.DB.Port, c.DB.Username, c.DB.Password, c.DB.DBName)
	db, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		panic(fmt.Errorf("could not open DB connection: %w", err))
	}
	logger.Info().Msg("DB connection established!")

	opt := option.WithCredentialsFile("serviceAccountKey.json")
	fb, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		panic(fmt.Errorf("error initializing firebaseApp: %v", err))
	}

	app := api.New(c, &logger, ctx, fb, db)

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", c.Server.Port),
		IdleTimeout:  c.Server.TimeoutIdle,
		ReadTimeout:  c.Server.TimeoutRead,
		WriteTimeout: c.Server.TimeoutWrite,
		Handler:      app.GetRouter(),
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Fatal().AnErr("listen: %s\n", err).Ctx(ctx)
		}
	}()

	logger.Info().Msg("Server startup successful!")

	<-ctx.Done()

	stop()
	logger.Warn().Msg("shutting down gracefully, press Ctrl+C again to force")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Error().AnErr("Server forced to shutdown: ", err)
	}

	logger.Info().Msg("Server exiting")
}
