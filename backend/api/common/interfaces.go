package common

import (
	"database/sql"
	"firebase.google.com/go/messaging"
	"github.com/rs/zerolog"
	"party-time/db"
)

type Controller interface {
	GetQ() *db.Queries
	GetLog() *zerolog.Logger
}

type MessagingController interface {
	Controller
	GetMsg() *messaging.Client
}

type DBController interface {
	Controller
	GetDB() *sql.DB
}
