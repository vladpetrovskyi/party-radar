package location

import (
	"database/sql"
	"errors"
	"firebase.google.com/go/messaging"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/api/common"
	"party-time/db"
)

type ClosingController struct {
	log *zerolog.Logger
	q   *db.Queries
	msg *messaging.Client
}

func NewClosingController(log *zerolog.Logger, q *db.Queries, msg *messaging.Client) *ClosingController {
	return &ClosingController{log: log, q: q, msg: msg}
}

func (ctl *ClosingController) GetQ() *db.Queries {
	return ctl.q
}

func (ctl *ClosingController) GetLog() *zerolog.Logger {
	return ctl.log
}

func (ctl *ClosingController) GetMsg() *messaging.Client {
	return ctl.msg
}

func (ctl *ClosingController) CreateLocationClosing(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = ctl.q.CreateLocationClosing(c, locationId)
	if err != nil {
		ctl.log.Error().Err(err).Msg("Failed to create location closing")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not create location closing", "err": err.Error()})
		return
	}

	c.Status(http.StatusCreated)
}

// GetLocationAvailability Deprecated
// TODO: GetLocationByID shall be used instead (or not? -> smaller REST-calls)
func (ctl *ClosingController) GetLocationAvailability(c *gin.Context) {
	locationID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	closingTime, err := ctl.q.GetLocationClosingTimeByLocationID(c, locationID)
	if errors.Is(err, sql.ErrNoRows) {
		c.Status(http.StatusNotFound)
		return
	}

	c.JSON(http.StatusOK, gin.H{"closed_at": closingTime})
}

// UpdateLocationAvailability Deprecated
// TODO: UpdateLocation shall be used instead (or not? -> smaller REST-calls)
func (ctl *ClosingController) UpdateLocationAvailability(c *gin.Context) {
	locationID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	location := struct {
		ClosedAt *string `json:"closed_at"`
	}{}
	err = c.Bind(&location)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var locationStatus string

	if location.ClosedAt == nil {
		if err := ctl.q.OpenLocationByID(c, locationID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		locationStatus = "opened"
	} else {
		if closingTime, err := ctl.q.GetLocationClosingTimeByLocationID(c, locationID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		} else if closingTime != nil {
			c.Status(http.StatusAlreadyReported)
			return
		}

		if err := ctl.q.CloseLocationByID(c, locationID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		locationStatus = "closed"
	}

	go sendLocationAvailabilityUpdateNotification(ctl, locationID, locationStatus, c)

	c.Status(http.StatusOK)
}

func (ctl *ClosingController) DeleteLocationClosing(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = ctl.q.DeleteLocationClosing(c, locationId)
	if err != nil {
		ctl.log.Error().Err(err).Msg("Failed to delete location closing")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not delete location closing", "err": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func sendLocationAvailabilityUpdateNotification(ctl common.MessagingController, locationID int64, locationStatus string, c *gin.Context) {
	location, err := ctl.GetQ().GetLocation(c, locationID)
	if err != nil {
		log.Err(err).Msg("Failed to get location on sendLocationAvailabilityUpdateNotification")
		return
	}

	users, err := ctl.GetQ().GetUsersByRootLocationID(c, location.RootLocationID)
	if err != nil {
		log.Err(err).Msg("Failed to get users by root location on sendLocationAvailabilityUpdateNotification")
		return
	}

	reportingUser, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		log.Err(err).Msg("Failed to get user from context on sendLocationAvailabilityUpdateNotification")
		return
	}

	messages := make([]*messaging.Message, 0)
	for _, user := range users {
		if user.FcmToken != nil && (reportingUser.FcmToken == nil || *reportingUser.FcmToken != *user.FcmToken) {
			message := messaging.Message{
				Notification: &messaging.Notification{
					Title: "Location status changed",
					Body:  "One of the locations has been " + locationStatus,
				},
				Data: map[string]string{
					"view": "location",
				},
				Token: *user.FcmToken,
			}

			messages = append(messages, &message)
		}
	}

	response, err := ctl.GetMsg().SendAll(c, messages)
	if err != nil {
		log.Err(err).Msg("Failed to sendLocationAvailabilityUpdateNotification")
		return
	}

	log.Debug().Msgf("Successfully sent %v / %v new post messages", response.SuccessCount, len(response.Responses))
}
