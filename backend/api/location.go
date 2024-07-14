package api

import (
	"database/sql"
	"errors"
	"firebase.google.com/go/messaging"
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
	"time"
)

type Location struct {
	ID                   int64      `json:"id"`
	Name                 string     `json:"name"`
	Emoji                *string    `json:"emoji"`
	Enabled              bool       `json:"enabled"`
	ElementType          *string    `json:"element_type"`
	OnClickAction        *string    `json:"on_click_action"`
	ColumnIndex          *int64     `json:"column_index"`
	RowIndex             *int64     `json:"row_index"`
	ColumnsNumber        *int64     `json:"columns_number"`
	DialogName           *string    `json:"dialog_name"`
	ImageID              *int64     `json:"image_id"`
	IsCapacitySelectable *bool      `json:"is_capacity_selectable"`
	IsCloseable          bool       `json:"is_closeable"`
	ClosedAt             *time.Time `json:"closed_at"`
	DeletedAt            *time.Time `json:"deleted_at"`
	Children             []Location `json:"children"`
	ParentID             *int64     `json:"-"`
	CreatedBy            *string    `json:"created_by"`
	IsOfficial           bool       `json:"is_official"`
}

func (app *Application) getLocations(c *gin.Context) {
	elementType := c.Query("type")
	if len(elementType) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Element type cannot be empty"})
	}

	locations, err := app.q.GetLocationsByElementType(c, &elementType)
	if err != nil {
		c.JSON(http.StatusNotFound, nil)
		return
	}

	c.JSON(200, locations)
}

// Deprecated
// No children should be returned with location, there is another endpoint for it
func (app *Application) getLocationByID(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocationRow, err := app.getAndMapLocationFromDb(locationId)
	if err != nil {
		app.log.Debug().AnErr("[ERROR] getLocationByID -> getAndMapLocationFromDb", err)
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocation, err := app.buildLocationFromParent(rootLocationRow)
	if err != nil {
		app.log.Debug().AnErr("[ERROR] getLocationByID -> buildLocationFromParent", err)
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rootLocation)
}

func (app *Application) getSelectedLocationIDs(c *gin.Context) {
	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	if user.CurrentLocationID == nil {
		c.JSON(http.StatusNoContent, gin.H{"msg": "user is not at any location currently"})
		return
	}

	location, err := app.q.GetLocation(c, *user.CurrentLocationID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	idArr, err := app.buildUpstreamIDListFromLocation(location, []int64{location.ID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, idArr)
}

func (app *Application) getLocationByIDV2(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocation, err := app.q.GetLocation(app.ctx, locationId)
	if err != nil {
		app.log.Debug().AnErr("[ERROR] getLocationByID -> getAndMapLocationFromDb", err)
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rootLocation)
}

func (app *Application) getLocationChildren(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	locationChildren, err := app.q.GetLocationChildren(c, &locationId)
	if err != nil {
		app.log.Debug().AnErr("[ERROR] getLocationChildren", err)
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, locationChildren)
}

func (app *Application) getLocationUserCount(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	usersAtLocation, err := app.countUsersAtLocationTree(c, locationId, user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"count": usersAtLocation})
}

func (app *Application) countUsersAtLocationTree(c *gin.Context, locationId, userId int64) (int64, error) {
	usersAtLocation, err := app.q.CountUsersAtLocation(app.ctx, db.CountUsersAtLocationParams{
		User2ID:           userId,
		CurrentLocationID: &locationId,
	})
	if err != nil {
		return 0, err
	}

	locationChildren, err := app.q.GetLocationChildren(c, &locationId)
	if err != nil {
		return 0, err
	}

	for _, child := range locationChildren {
		usersAtChildLocation, err := app.countUsersAtLocationTree(c, child.ID, userId)
		if err != nil {
			return 0, err
		}
		usersAtLocation += usersAtChildLocation
	}
	return usersAtLocation, nil
}

func (app *Application) getAndMapLocationFromDb(locationId int64) (Location, error) {
	rootLocationRow, err := app.q.GetLocation(app.ctx, locationId)
	if err != nil {
		return Location{}, err
	}
	return app.mapLocation(rootLocationRow), nil
}

func (app *Application) buildLocationFromParent(location Location) (Location, error) {
	locations, err := app.q.GetLocationChildren(app.ctx, &location.ID)
	if err != nil {
		return location, err
	} else if len(locations) > 0 {
		for _, l := range locations {
			childLocation, err := app.buildLocationFromParent(app.mapLocationChild(l))
			if err != nil {
				return location, err
			}
			location.Children = append(location.Children, childLocation)
		}
	}
	return location, nil
}

func (app *Application) buildLocationFromChild(location Location) (Location, error) {
	if location.ParentID == nil {
		return location, nil
	}
	parentLocationRow, err := app.q.GetLocation(app.ctx, *location.ParentID)
	if err != nil {
		return location, err
	}

	parentLocation := app.mapLocation(parentLocationRow)
	parentLocation.Children = append(parentLocation.Children, location)
	parentLocation, err = app.buildLocationFromChild(parentLocation)
	return parentLocation, err
}

func (app *Application) buildUpstreamIDListFromLocation(location db.GetLocationRow, idArr []int64) ([]int64, error) {
	if location.ParentID == nil {
		return idArr, nil
	}
	parentLocationRow, err := app.q.GetLocation(app.ctx, *location.ParentID)
	if err != nil {
		return idArr, err
	}

	idArr = append(idArr, parentLocationRow.ID)
	idArr, err = app.buildUpstreamIDListFromLocation(parentLocationRow, idArr)
	return idArr, err
}

func (app *Application) mapLocationChild(dbLocation db.GetLocationChildrenRow) Location {
	return Location{
		ID:                   dbLocation.ID,
		Name:                 *dbLocation.Name,
		Emoji:                dbLocation.Emoji,
		Enabled:              dbLocation.Enabled,
		ElementType:          dbLocation.ElementType,
		OnClickAction:        dbLocation.OnClickAction,
		ColumnIndex:          dbLocation.ColumnIndex,
		RowIndex:             dbLocation.RowIndex,
		ColumnsNumber:        dbLocation.ColumnsNumber,
		DialogName:           dbLocation.DialogName,
		ImageID:              dbLocation.ImageID,
		IsCapacitySelectable: dbLocation.IsCapacitySelectable,
		IsCloseable:          dbLocation.IsCloseable,
		ClosedAt:             dbLocation.ClosedAt,
		DeletedAt:            dbLocation.DeletedAt,
		Children:             []Location{},
		ParentID:             dbLocation.ParentID,
	}
}

func (app *Application) mapLocation(dbLocation db.GetLocationRow) Location {
	return Location{
		ID:                   dbLocation.ID,
		Name:                 *dbLocation.Name,
		Emoji:                dbLocation.Emoji,
		Enabled:              dbLocation.Enabled,
		ElementType:          dbLocation.ElementType,
		OnClickAction:        dbLocation.OnClickAction,
		ColumnIndex:          dbLocation.ColumnIndex,
		RowIndex:             dbLocation.RowIndex,
		ColumnsNumber:        dbLocation.ColumnsNumber,
		DialogName:           dbLocation.DialogName,
		ImageID:              dbLocation.ImageID,
		IsCapacitySelectable: dbLocation.IsCapacitySelectable,
		IsCloseable:          dbLocation.IsCloseable,
		ClosedAt:             dbLocation.ClosedAt,
		DeletedAt:            dbLocation.DeletedAt,
		Children:             []Location{},
		ParentID:             dbLocation.ParentID,
		CreatedBy:            dbLocation.CreatedBy,
		IsOfficial:           dbLocation.IsOfficial,
	}
}

// Deprecated
// TODO: GetLocationByID shall be used instead
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
// TODO: UpdateLocation shall be used instead!
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
		app.log.Err(err)
		return
	}

	users, err := app.q.GetUsersByRootLocationID(app.ctx, location.RootLocationID)
	if err != nil {
		app.log.Err(err)
		return
	}

	reportingUser, err := app.getUserFromContext(c)
	if err != nil {
		app.log.Err(err)
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
		app.log.Err(err)
		return
	}

	app.log.Debug().Msgf("Successfully sent %v / %v new post messages", response.SuccessCount, len(response.Responses))
}
