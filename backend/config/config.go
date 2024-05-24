package config

import (
	"github.com/joeshaw/envdecode"
	"log"
	"time"
)

type Conf struct {
	Server ConfServer
	DB     ConfDB
}

type ConfServer struct {
	Port         int           `env:"SERVER_PORT,default=8080"`
	TimeoutRead  time.Duration `env:"SERVER_TIMEOUT_READ,default=5s"`
	TimeoutWrite time.Duration `env:"SERVER_TIMEOUT_WRITE,default=10s"`
	TimeoutIdle  time.Duration `env:"SERVER_TIMEOUT_IDLE,default=60s"`
	Debug        bool          `env:"SERVER_DEBUG,default=false"`
	Environment  string        `env:"SERVER_ENVIRONMENT,default=local"`
}

type ConfDB struct {
	Host              string `env:"DATASOURCE_HOST,default=localhost"`
	Port              int    `env:"DB_PORT,default=5432"`
	Username          string `env:"POSTGRES_USER,default=postgres"`
	Password          string `env:"POSTGRES_PASSWORD,default=pass"`
	DBName            string `env:"POSTGRES_DB,default=party-radar"`
	Debug             bool   `env:"DB_DEBUG"`
	IsDockerContainer bool   `env:"IS_DOCKER_CONTAINER,default=false"`
}

func New() *Conf {
	var c Conf
	if err := envdecode.StrictDecode(&c); err != nil {
		log.Fatalf("Failed to decode: %s", err)
	}

	return &c
}

func NewDB() *ConfDB {
	var c ConfDB
	if err := envdecode.StrictDecode(&c); err != nil {
		log.Fatalf("Failed to decode: %s", err)
	}

	return &c
}
