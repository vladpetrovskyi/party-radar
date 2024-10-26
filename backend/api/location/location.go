package location

import (
	"database/sql"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"net/http"
	"party-time/api/common"
	"party-time/api/user"
	"party-time/db"
	"strconv"
	"time"
)

type Controller struct {
	log *zerolog.Logger
	q   *db.Queries
	db  *sql.DB
}

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

func NewController(log *zerolog.Logger, q *db.Queries, db *sql.DB) *Controller {
	return &Controller{log: log, q: q, db: db}
}

func (ctl *Controller) GetQ() *db.Queries {
	return ctl.q
}

func (ctl *Controller) GetLog() *zerolog.Logger {
	return ctl.log
}

func (ctl *Controller) GetDB() *sql.DB {
	return ctl.db
}

func (ctl *Controller) CreateLocation(c *gin.Context) {
	var location Location
	err := c.BindJSON(&location)
	if err != nil {
		ctl.log.Debug().Err(err).Msg("Could not bind JSON to create location")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse location", "err": err.Error()})
		return
	}

	u, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		ctl.log.Debug().Err(err).Msg("Could not get u from context to create location")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not get context u", "err": err.Error()})
		return
	}

	enabled := false
	if location.Enabled != nil {
		enabled = *location.Enabled
	}

	createdLocation, err := ctl.q.CreateLocation(c, db.CreateLocationParams{
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
		OwnerID:           &u.ID,
	})
	if err != nil {
		ctl.log.Error().Err(err).Msg("Could not create location")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not create location", "err": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, createdLocation)
}

func (ctl *Controller) GetLocations(c *gin.Context) {
	query := &struct {
		Type    *string `json:"type"`
		Enabled *bool   `json:"enabled"`
	}{}
	if err := c.BindQuery(query); err != nil {
		ctl.log.Error().Err(err).Msg("Could not bind query")
		return
	}

	u, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		ctl.log.Error().Err(err).Msg("Could not get u from context")
		c.Status(http.StatusInternalServerError)
		return
	}

	locations, err := ctl.q.GetLocations(c, db.GetLocationsParams{
		ElementTypeName: query.Type,
		UserID:          u.ID,
	})
	if err != nil {
		c.JSON(http.StatusNotFound, nil)
		return
	}

	c.JSON(200, locations)
}

// GetLocationByID Deprecated
// No children should be returned with location, there is another endpoint for it
func (ctl *Controller) GetLocationByID(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocationRow, err := GetAndMapLocationFromDb(ctl.q, c, locationId)
	if err != nil {
		ctl.log.Debug().AnErr("[ERROR] GetLocationByID -> getAndMapLocationFromDb", err)
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocation, err := buildLocationFromParent(ctl.q, c, rootLocationRow)
	if err != nil {
		ctl.log.Debug().AnErr("[ERROR] GetLocationByID -> buildLocationFromParent", err)
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rootLocation)
}

func (ctl *Controller) GetSelectedLocationIDs(c *gin.Context) {
	u, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	if u.CurrentLocationID == nil {
		c.JSON(http.StatusNoContent, gin.H{"msg": "u is not at any location currently"})
		return
	}

	location, err := ctl.q.GetLocation(c, *u.CurrentLocationID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	idArr, err := buildUpstreamIDListFromLocation(ctl.q, c, location, []int64{location.ID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, idArr)
}

func (ctl *Controller) GetLocationByIDV2(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocation, err := ctl.q.GetLocation(c, locationId)
	if err != nil {
		ctl.log.Debug().AnErr("[ERROR] GetLocationByID -> getAndMapLocationFromDb", err)
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rootLocation)
}

func (ctl *Controller) UpdateLocation(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	var location Location
	if err = c.BindJSON(&location); err != nil {
		ctl.log.Debug().Err(err).Msg("Could not bind JSON to update location")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse location", "err": err.Error()})
		return
	}

	var isLocationDisabled = location.Enabled != nil && !*location.Enabled

	if isLocationDisabled {
		usersByRootLocationID, err := ctl.q.GetUsersByRootLocationID(c, &locationId)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"message": "Could not get users at root location with ID=" + strconv.FormatInt(locationId, 10), "err": err.Error()})
			return
		}

		for _, u := range usersByRootLocationID {
			if err = user.DeleteUserLocation(ctl, u.ID, u.CurrentRootLocationID, c); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"message": "Could not check out u with ID=" + strconv.FormatInt(u.ID, 10), "err": err.Error()})
				return
			}
		}
	}

	updatedLocation, err := ctl.q.UpdateLocation(c, db.UpdateLocationParams{
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
		ctl.log.Error().Err(err).Msg("Could not update location")
		c.JSON(http.StatusInternalServerError, gin.H{"message": "Could not create location", "err": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updatedLocation)
}

func (ctl *Controller) DeleteLocation(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		ctl.log.Debug().Err(err).Msg("Could not read ID param to delete a location")
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	postsCount, err := ctl.q.GetLocationPostsCount(c, locationId)
	if err != nil {
		ctl.log.Debug().AnErr("[ERROR] deleteLocation -> GetLocationPostsCount", err)
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if postsCount == 0 {
		err = ctl.q.DeleteLocation(c, locationId)
		if err != nil {
			ctl.log.Debug().Err(err).Msg("[ERROR] deleteLocation -> DeleteLocation")
			c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
			return
		}
		c.Status(http.StatusOK)
		return
	}

	err = ctl.q.SetLocationDeletedAt(c, locationId)
	if err != nil {
		ctl.log.Debug().AnErr("[ERROR] deleteLocation -> SetLocationDeletedAt", err)
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (ctl *Controller) GetLocationChildren(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	locationChildren, err := ctl.q.GetLocationChildren(c, &locationId)
	if err != nil {
		ctl.log.Debug().AnErr("[ERROR] getLocationChildren", err)
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, locationChildren)
}

func (ctl *Controller) GetLocationUserCount(c *gin.Context) {
	locationId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	u, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	usersAtLocation, err := countUsersAtLocationTree(ctl.q, c, locationId, u.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"count": usersAtLocation})
}

func countUsersAtLocationTree(q *db.Queries, c *gin.Context, locationId, userId int64) (int64, error) {
	usersAtLocation, err := q.CountUsersAtLocation(c, db.CountUsersAtLocationParams{
		User2ID:           userId,
		CurrentLocationID: &locationId,
	})
	if err != nil {
		return 0, err
	}

	locationChildren, err := q.GetLocationChildren(c, &locationId)
	if err != nil {
		return 0, err
	}

	for _, child := range locationChildren {
		usersAtChildLocation, err := countUsersAtLocationTree(q, c, child.ID, userId)
		if err != nil {
			return 0, err
		}
		usersAtLocation += usersAtChildLocation
	}
	return usersAtLocation, nil
}

func GetAndMapLocationFromDb(q *db.Queries, c *gin.Context, locationId int64) (Location, error) {
	rootLocationRow, err := q.GetLocation(c, locationId)
	if err != nil {
		return Location{}, err
	}
	return mapLocation(rootLocationRow), nil
}

func buildLocationFromParent(q *db.Queries, c *gin.Context, location Location) (Location, error) {
	locations, err := q.GetLocationChildren(c, location.ID)
	if err != nil {
		return location, err
	} else if len(locations) > 0 {
		for _, l := range locations {
			childLocation, err := buildLocationFromParent(q, c, mapLocationChild(l))
			if err != nil {
				return location, err
			}
			location.Children = append(location.Children, childLocation)
		}
	}
	return location, nil
}

func BuildLocationFromChild(q *db.Queries, c *gin.Context, location Location) (Location, error) {
	if location.ParentID == nil {
		return location, nil
	}
	parentLocationRow, err := q.GetLocation(c, *location.ParentID)
	if err != nil {
		return location, err
	}

	parentLocation := mapLocation(parentLocationRow)
	parentLocation.Children = append(parentLocation.Children, location)
	parentLocation, err = BuildLocationFromChild(q, c, parentLocation)
	return parentLocation, err
}

func buildUpstreamIDListFromLocation(q *db.Queries, c *gin.Context, location db.GetLocationRow, idArr []int64) ([]int64, error) {
	if location.ParentID == nil {
		return idArr, nil
	}
	parentLocationRow, err := q.GetLocation(c, *location.ParentID)
	if err != nil {
		return idArr, err
	}

	idArr = append(idArr, parentLocationRow.ID)
	idArr, err = buildUpstreamIDListFromLocation(q, c, parentLocationRow, idArr)
	return idArr, err
}

func mapLocationChild(dbLocation db.GetLocationChildrenRow) Location {
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

func mapLocation(dbLocation db.GetLocationRow) Location {
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
