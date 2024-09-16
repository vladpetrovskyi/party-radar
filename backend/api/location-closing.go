package api

import (
	"database/sql"
	"errors"
	"firebase.google.com/go/messaging"
	"github.com/gin-gonic/gin"
	"net/http"
)

func (app *Application) createLocationClosing(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = app.q.CreateLocationClosing(c, locationId)
	if err != nil {
		app.log.Error().Err(err).Msg("Failed to create location closing")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not create location closing", "err": err.Error()})
		return
	}

	c.Status(http.StatusCreated)
}

func (app *Application) deleteLocationClosing(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = app.q.DeleteLocationClosing(c, locationId)
	if err != nil {
		app.log.Error().Err(err).Msg("Failed to delete location closing")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not delete location closing", "err": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

// Deprecated
// TODO: GetLocationByID shall be used instead (or not? -> smaller REST-calls)
func (app *Application) getLocationAvailability(c *gin.Context) {
	locationID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	closingTime, err := app.q.GetLocationClosingTimeByLocationID(c, locationID)
	if errors.Is(err, sql.ErrNoRows) {
		c.Status(http.StatusNotFound)
		return
	}

	c.JSON(http.StatusOK, gin.H{"closed_at": closingTime})
}

// Deprecated
// TODO: UpdateLocation shall be used instead (or not? -> smaller REST-calls)
func (app *Application) updateLocationAvailability(c *gin.Context) {
	locationID, err := app.readIDParam(c)
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
		if err := app.q.OpenLocationByID(c, locationID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		locationStatus = "opened"
	} else {
		if closingTime, err := app.q.GetLocationClosingTimeByLocationID(c, locationID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		} else if closingTime != nil {
			c.Status(http.StatusAlreadyReported)
			return
		}

		if err := app.q.CloseLocationByID(c, locationID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		locationStatus = "closed"
	}

	go app.sendLocationAvailabilityUpdateNotification(locationID, locationStatus, c)

	c.Status(http.StatusOK)
}

func (app *Application) sendLocationAvailabilityUpdateNotification(locationID int64, locationStatus string, c *gin.Context) {
	location, err := app.q.GetLocation(app.ctx, locationID)
	if err != nil {
		app.log.Err(err).Msg("Failed to get location on sendLocationAvailabilityUpdateNotification")
		return
	}

	users, err := app.q.GetUsersByRootLocationID(app.ctx, location.RootLocationID)
	if err != nil {
		app.log.Err(err).Msg("Failed to get users by root location on sendLocationAvailabilityUpdateNotification")
		return
	}

	reportingUser, err := app.getUserFromContext(c)
	if err != nil {
		app.log.Err(err).Msg("Failed to get user from context on sendLocationAvailabilityUpdateNotification")
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

	response, err := app.msg.SendAll(app.ctx, messages)
	if err != nil {
		app.log.Err(err).Msg("Failed to sendLocationAvailabilityUpdateNotification")
		return
	}

	app.log.Debug().Msgf("Successfully sent %v / %v new post messages", response.SuccessCount, len(response.Responses))
}
