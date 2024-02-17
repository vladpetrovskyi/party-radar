package db

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"github.com/pressly/goose/v3"
	"github.com/rs/zerolog"
	"io/fs"
	"party-time/internal"
	"strconv"
	"strings"
)

type db struct {
	db      *sql.DB
	queries *Queries
	log     *zerolog.Logger
}

var (
	//go:embed migrations/*.sql
	embedMigrations embed.FS

	//go:embed seeds/*.sql
	embedSeeds embed.FS

	//go:embed seeds/assets/*.png
	embedImages embed.FS
)

func Init(ctx context.Context, log *zerolog.Logger) (*sql.DB, *Queries) {
	log.Info().Msg("Connecting to DB...")

	database := &db{log: log}

	var (
		host     = internal.GetEnvVar("DATASOURCE_HOST", internal.GetDefaultHost())
		port     = 5432
		user     = internal.GetEnvVar("POSTGRES_USER", "postgres")
		password = internal.GetEnvVar("POSTGRES_PASSWORD", "pass")
		dbname   = internal.GetEnvVar("POSTGRES_DB", "party-radar")
	)

	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)
	dbConnection, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		panic(fmt.Errorf("could not open DB connection: %w", err))
	}

	err = dbConnection.Ping()
	if err != nil {
		panic(fmt.Errorf("could not ping DB: %w", err))
	}

	database.db = dbConnection
	database.queries = New(database.db)

	database.applyMigrations()

	err = database.populateImages(ctx)
	if err != nil {
		panic(fmt.Errorf("failed to populate images into DB: %w", err))
	}

	database.populateSeeds()

	return database.db, database.queries
}

func (db *db) applyMigrations() {
	db.log.Info().Msg("Applying DB migrations...")
	goose.SetBaseFS(embedMigrations)
	if err := goose.SetDialect("postgres"); err != nil {
		panic(err)
	}
	if err := goose.Up(db.db, "migrations"); err != nil {
		panic(err)
	}
}

func (db *db) populateImages(c context.Context) error {
	dirName := "seeds/assets"
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

		err = db.queries.UpsertImage(c, UpsertImageParams{
			ID:       imageId,
			FileName: fileName,
			Content:  file,
		})
		if err != nil {
			return err
		}
	}

	err = db.queries.ResetImageSequence(c)
	if err != nil {
		return err
	}

	return nil
}

func (db *db) populateSeeds() {
	db.log.Info().Msg("Populating seeds into DB...")
	goose.SetBaseFS(embedSeeds)
	if err := goose.SetDialect("postgres"); err != nil {
		panic(err)
	}
	if err := goose.Up(db.db, "seeds", goose.WithAllowMissing()); err != nil {
		panic(err)
	}
}
