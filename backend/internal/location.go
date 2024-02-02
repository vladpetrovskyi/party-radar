package internal

import (
	"context"
	"database/sql"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"party-time/db"
	"strconv"
)

type Location struct {
	ID            int64      `json:"id"`
	Name          string     `json:"name"`
	Emoji         *string    `json:"emoji"`
	Enabled       bool       `json:"enabled"`
	ElementType   *string    `json:"element_type"`
	OnClickAction *string    `json:"on_click_action"`
	ColumnIndex   *int64     `json:"column_index"`
	ColumnsNumber *int64     `json:"columns_number"`
	DialogName    *string    `json:"dialog_name"`
	ImageID       *int64     `json:"image_id"`
	Children      []Location `json:"children"`
	ParentID      *int64
}

type LocationHandler struct {
	Queries *db.Queries
	DB      *sql.DB
	Ctx     context.Context
}

func (h *LocationHandler) GetLocations(c *gin.Context) {
	elementType := c.Query("type")
	if len(elementType) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Element type cannot be empty"})
	}

	locations, err := h.Queries.GetLocationsByElementType(c, &elementType)
	if err != nil {
		c.JSON(http.StatusNotFound, nil)
		return
	}

	c.JSON(200, locations)
}

func (h *LocationHandler) GetLocation(c *gin.Context) {
	locationId, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		log.Printf("[ERROR] parseLocationId: %v", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocationRow, err := h.getAndMapLocationFromDb(locationId)
	if err != nil {
		log.Printf("[ERROR] GetLocation -> getAndMapLocationFromDb: %v", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	rootLocation, err := h.buildLocationFromParent(rootLocationRow)
	if err != nil {
		log.Printf("[ERROR] GetLocation -> buildLocationFromParent: %v", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rootLocation)
}

func (h *LocationHandler) GetLocationUserCount(c *gin.Context) {
	locationId, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		log.Printf("[ERROR] parseLocationId: %v", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	uid := c.GetString("tokenUID")
	user, err := h.Queries.GetUserByUID(c, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	usersAtLocation, err := h.countUsersAtLocationTree(c, locationId, user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"count": usersAtLocation})
}

func (h *LocationHandler) countUsersAtLocationTree(c *gin.Context, locationId, userId int64) (int64, error) {
	usersAtLocation, err := h.Queries.CountUsersAtLocation(h.Ctx, db.CountUsersAtLocationParams{
		User2ID:           userId,
		CurrentLocationID: &locationId,
	})
	if err != nil {
		return 0, err
	}

	locationChildren, err := h.Queries.GetLocationChildren(c, &locationId)
	if err != nil {
		return 0, err
	}

	for _, child := range locationChildren {
		usersAtChildLocation, err := h.countUsersAtLocationTree(c, child.ID, userId)
		if err != nil {
			return 0, err
		}
		usersAtLocation += usersAtChildLocation
	}
	return usersAtLocation, nil
}

func (h *LocationHandler) getAndMapLocationFromDb(locationId int64) (Location, error) {
	rootLocationRow, err := h.Queries.GetLocation(h.Ctx, locationId)
	if err != nil {
		return Location{}, err
	}
	return h.mapLocation(rootLocationRow), nil
}

func (h *LocationHandler) buildLocationFromParent(location Location) (Location, error) {
	locations, err := h.Queries.GetLocationChildren(h.Ctx, &location.ID)
	if err != nil {
		return location, err
	} else if len(locations) > 0 {
		for _, l := range locations {
			childLocation, err := h.buildLocationFromParent(h.mapLocationChild(l))
			if err != nil {
				return location, err
			}
			location.Children = append(location.Children, childLocation)
		}
	}
	return location, nil
}

func (h *LocationHandler) buildLocationFromChild(location Location) (Location, error) {
	if location.ParentID == nil {
		return location, nil
	}
	parentLocationRow, err := h.Queries.GetLocation(h.Ctx, *location.ParentID)
	if err != nil {
		return location, err
	}

	parentLocation := h.mapLocation(parentLocationRow)
	parentLocation.Children = append(parentLocation.Children, location)
	parentLocation, err = h.buildLocationFromChild(parentLocation)
	return parentLocation, err
}

func (h *LocationHandler) mapLocationChild(dbLocation db.GetLocationChildrenRow) Location {
	return Location{
		ID:            dbLocation.ID,
		Name:          *dbLocation.Name,
		Emoji:         dbLocation.Emoji,
		Enabled:       dbLocation.Enabled,
		ElementType:   dbLocation.ElementType,
		OnClickAction: dbLocation.OnClickAction,
		ColumnIndex:   dbLocation.ColumnIndex,
		ColumnsNumber: dbLocation.ColumnsNumber,
		DialogName:    dbLocation.DialogName,
		ImageID:       dbLocation.ImageID,
		Children:      []Location{},
	}
}

func (h *LocationHandler) mapLocation(dbLocation db.GetLocationRow) Location {
	return Location{
		ID:            dbLocation.ID,
		Name:          *dbLocation.Name,
		Emoji:         dbLocation.Emoji,
		Enabled:       dbLocation.Enabled,
		ElementType:   dbLocation.ElementType,
		OnClickAction: dbLocation.OnClickAction,
		ColumnIndex:   dbLocation.ColumnIndex,
		ColumnsNumber: dbLocation.ColumnsNumber,
		DialogName:    dbLocation.DialogName,
		ImageID:       dbLocation.ImageID,
		Children:      []Location{},
		ParentID:      dbLocation.ParentID,
	}
}
