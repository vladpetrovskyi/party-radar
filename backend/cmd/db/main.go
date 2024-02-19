package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"os"
	"party-time/config"
	"party-time/db"
	"runtime"
	"strconv"
	"strings"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

const (
	dialect     = "pgx"
	fmtDBString = "host=%s user=%s password=%s dbname=%s port=%d sslmode=disable"
)

var (
	flags         = flag.NewFlagSet("migrate", flag.ExitOnError)
	migrationsDir = flags.String("migrationsDir", "db/migrations", "directory with migration files")
	seedsDir      = flags.String("seedsDir", "db/seeds", "directory with migration files")
	assetsDir     = flags.String("assets", "db/seeds/assets", "directory with migration files")
)

func main() {
	var logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.TimeOnly})

	flags.Usage = usage
	err := flags.Parse(os.Args[1:])
	if err != nil {
		logger.Fatal().Err(err)
	}

	args := flags.Args()
	if len(args) == 0 || args[0] == "-h" || args[0] == "--help" {
		flags.Usage()
		return
	}

	command := args[0]

	c := config.NewDB()

	if c.Host == "localhost" {
		if (runtime.GOOS == "darwin" || runtime.GOOS == "linux") && c.IsDockerContainer {
			c.Host = "docker.for.mac.localhost"
		}
	}

	dbString := fmt.Sprintf(fmtDBString, c.Host, c.Username, c.Password, c.DBName, c.Port)

	database, err := goose.OpenDBWithDriver(dialect, dbString)
	if err != nil {
		logger.Fatal().Err(err)
	}

	defer func() {
		if err := database.Close(); err != nil {
			logger.Fatal().Err(err)
		}
	}()

	if err := goose.RunContext(context.Background(), command, database, *migrationsDir, args[1:]...); err != nil {
		logger.Fatal().Msgf("migrate %v: %v", command, err)
	}

	if err := goose.RunContext(context.Background(), command, database, *seedsDir, args[1:]...); err != nil {
		logger.Fatal().Msgf("seeds %v: %v", command, err)
	}

	dirFiles, err := os.ReadDir(*assetsDir)
	if err != nil {
		logger.Fatal().Msgf("db/seeds/assets: %v", err)
	}

	queries := db.New(database)

	for _, f := range dirFiles {
		info, err := f.Info()
		if err != nil {
			logger.Fatal().Msgf("db/seeds/assets: %v", err)
		}
		fileName := info.Name()
		imageId, err := strconv.ParseInt(strings.Split(fileName, "_")[0], 10, 64)
		if err != nil {
			logger.Fatal().Msgf("db/seeds/assets: %v", err)
		}

		file, err := os.ReadFile(*assetsDir + "/" + fileName)
		if err != nil {
			logger.Fatal().Msgf("db/seeds/assets: %v", err)
		}

		err = queries.UpsertImage(context.Background(), db.UpsertImageParams{
			ID:       imageId,
			FileName: fileName,
			Content:  file,
		})
		if err != nil {
			logger.Fatal().Msgf("db/seeds/assets: %v", err)
		}
	}

	err = queries.ResetImageSequence(context.Background())
	if err != nil {
		logger.Fatal().Msgf("db/seeds/assets: %v", err)
	}
}

func usage() {
	fmt.Println(usagePrefix)
	flags.PrintDefaults()
	fmt.Println(usageCommands)
}

var (
	usagePrefix = `
Usage: migrate COMMAND
Examples:
    migrate status`

	usageCommands = `
Commands:
    up                   Migrate the DB to the most recent version available
    up-by-one            Migrate the DB up by 1
    up-to VERSION        Migrate the DB to a specific VERSION
    down                 Roll back the version by 1
    down-to VERSION      Roll back to a specific VERSION
    redo                 Re-run the latest migration
    reset                Roll back all migrations
    status               Dump the migration status for the current DB
    version              Print the current version of the database
    create NAME [sql|go] Creates new migration file with the current timestamp
    fix                  Apply sequential ordering to migrations`
)
