package api

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
	"strconv"
	"time"
)

type Location struct {
	ID            *int64  `json:"id"`
	Name          string  `json:"name"`
	Emoji         *string `json:"emoji"`
	Enabled       *bool   `json:"enabled"`
	ElementType   *string `json:"element_type"`
	OnClickAction *string `json:"on_click_action"`
	ColumnIndex   *int64  `json:"column_index"`
	RowIndex      *int64  `json:"row_index"`
	// Deprecated, now in DialogSettings
	ColumnsNumber *int64 `json:"columns_number"`
	// Deprecated, now in DialogSettings
	DialogName *string `json:"dialog_name"`
	// Deprecated, now in DialogSettings
	ImageID          *int64 `json:"image_id"`
	DialogSettingsID *int64 `json:"dialog_settings_id"`
	RootLocationID   *int64 `json:"root_location_id"`
	// Deprecated, now in DialogSettings
	IsCapacitySelectable *bool      `json:"is_capacity_selectable"`
	IsCloseable          bool       `json:"is_closeable"`
	ClosedAt             *time.Time `json:"closed_at"`
	DeletedAt            *time.Time `json:"deleted_at"`
	Children             []Location `json:"children"`
	ParentID             *int64     `json:"parent_id"`
	CreatedBy            *string    `json:"created_by"`
	IsOfficial           bool       `json:"is_official"`
}

func (app *Application) createLocation(c *gin.Context) {
	var location Location
	err := c.BindJSON(&location)
	if err != nil {
		app.log.Debug().Err(err).Msg("Could not bind JSON to create location")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse location", "err": err.Error()})
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		app.log.Debug().Err(err).Msg("Could not get user from context to create location")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not get context user", "err": err.Error()})
		return
	}

	enabled := false
	if location.Enabled != nil {
		enabled = *location.Enabled
	}

	createdLocation, err := app.q.CreateLocation(c, db.CreateLocationParams{
		Name:              &location.Name,
		Emoji:             location.Emoji,
		Enabled:           &enabled,
		ElementTypeName:   location.ElementType,
		OnClickActionName: location.OnClickAction,
		ColumnIndex:       location.ColumnIndex,
		RowIndex:          location.RowIndex,
		ParentID:          location.ParentID,
		RootLocationID:    location.RootLocationID,
		IsOfficial:        &location.IsOfficial,
		OwnerID:           &user.ID,
	})
	if err != nil {
		app.log.Error().Err(err).Msg("Could not create location")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not create location", "err": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, createdLocation)
}

func (app *Application) getLocations(c *gin.Context) {
	query := &struct {
		Type    *string `json:"type"`
		Enabled *bool   `json:"enabled"`
	}{}
	if err := c.BindQuery(query); err != nil {
		app.log.Error().Err(err).Msg("Could not bind query")
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		app.log.Error().Err(err).Msg("Could not get user from context")
		c.Status(http.StatusInternalServerError)
		return
	}

	locations, err := app.q.GetLocations(c, db.GetLocationsParams{
		ElementTypeName: query.Type,
		UserID:          user.ID,
	})
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

func (app *Application) updateLocation(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	var location Location
	if err = c.BindJSON(&location); err != nil {
		app.log.Debug().Err(err).Msg("Could not bind JSON to update location")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse location", "err": err.Error()})
		return
	}

	if location.Enabled != nil && !*location.Enabled {
		usersByRootLocationID, err := app.q.GetUsersByRootLocationID(c, &locationId)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Could not get users at root location with ID=" + strconv.FormatInt(locationId, 10), "err": err.Error()})
			return
		}

		for _, user := range usersByRootLocationID {
			if err = app.deleteUserLocations(user.ID); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"message": "Could not check out user with ID=" + strconv.FormatInt(user.ID, 10), "err": err.Error()})
				return
			}

			if err = app.createPostForUser(user.ID, locationId, "end", nil); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"message": "Could not post checkout for user with ID=" + strconv.FormatInt(user.ID, 10), "err": err.Error()})
				return
			}
		}
	}

	updatedLocation, err := app.q.UpdateLocation(c, db.UpdateLocationParams{
		Name:              &location.Name,
		ID:                locationId,
		Emoji:             location.Emoji,
		Enabled:           location.Enabled,
		ElementTypeName:   location.ElementType,
		OnClickActionName: location.OnClickAction,
		ColumnIndex:       location.ColumnIndex,
		RowIndex:          location.RowIndex,
		ParentID:          location.ParentID,
		RootLocationID:    location.RootLocationID,
	})
	if err != nil {
		app.log.Error().Err(err).Msg("Could not update location")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not create location", "err": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updatedLocation)
}

func (app *Application) deleteLocation(c *gin.Context) {
	locationId, err := app.readIDParam(c)
	if err != nil {
		app.log.Debug().Err(err).Msg("Could not read ID param to delete a location")
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	postsCount, err := app.q.GetLocationPostsCount(c, locationId)
	if err != nil {
		app.log.Debug().AnErr("[ERROR] deleteLocation -> GetLocationPostsCount", err)
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if postsCount == 0 {
		err = app.q.DeleteLocation(app.ctx, locationId)
		if err != nil {
			app.log.Debug().Err(err).Msg("[ERROR] deleteLocation -> DeleteLocation")
			c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
			return
		}
		c.Status(http.StatusOK)
		return
	}

	err = app.q.SetLocationDeletedAt(app.ctx, locationId)
	if err != nil {
		app.log.Debug().AnErr("[ERROR] deleteLocation -> SetLocationDeletedAt", err)
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.Status(http.StatusOK)
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
	locations, err := app.q.GetLocationChildren(app.ctx, location.ID)
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
		ID:                   &dbLocation.ID,
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
		ID:                   &dbLocation.ID,
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
