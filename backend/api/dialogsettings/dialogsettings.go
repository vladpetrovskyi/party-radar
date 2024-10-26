package dialogsettings

import (
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"net/http"
	"party-time/api/common"
	"party-time/db"
)

type Controller struct {
	log *zerolog.Logger
	q   *db.Queries
}

type DialogSettings struct {
	ID                   *int64 `json:"id"`
	Name                 string `json:"name"`
	ColumnsNumber        *int64 `json:"columns_number"`
	IsCapacitySelectable *bool  `json:"is_capacity_selectable"`
	LocationID           int64  `json:"location_id"`
}

func NewController(log *zerolog.Logger, q *db.Queries) *Controller {
	return &Controller{log: log, q: q}
}

func (ctl *Controller) GetQ() *db.Queries {
	return ctl.q
}

func (ctl *Controller) GetLog() *zerolog.Logger {
	return ctl.log
}

func (ctl *Controller) CreateDialogSettings(c *gin.Context) {
	var dialogSettingsDTO DialogSettings
	err := c.BindJSON(&dialogSettingsDTO)
	if err != nil {
		ctl.log.Debug().Err(err).Msg("Could not parse dialog settings")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse dialog settings", "err": err.Error()})
		return
	}

	dialogSettings, err := ctl.q.CreateDialogSettings(c, db.CreateDialogSettingsParams{
		Name:                 &dialogSettingsDTO.Name,
		ColumnsNumber:        dialogSettingsDTO.ColumnsNumber,
		IsCapacitySelectable: dialogSettingsDTO.IsCapacitySelectable,
		LocationID:           dialogSettingsDTO.LocationID,
	})
	if err != nil {
		ctl.log.Error().Err(err).Msg("Could not create dialog settings")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "Could not create dialog settings", "err": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, dialogSettings)
}

func (ctl *Controller) UpdateDialogSettings(c *gin.Context) {
	dialogSettingsId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	var dialogSettingsDTO DialogSettings
	err = c.BindJSON(&dialogSettingsDTO)
	if err != nil {
		ctl.log.Debug().Err(err).Msg("Could not parse dialog settings")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse dialog settings", "err": err.Error()})
		return
	}

	err = ctl.q.UpdateDialogSettings(c, db.UpdateDialogSettingsParams{
		ID:                   &dialogSettingsId,
		Name:                 &dialogSettingsDTO.Name,
		ColumnsNumber:        dialogSettingsDTO.ColumnsNumber,
		IsCapacitySelectable: dialogSettingsDTO.IsCapacitySelectable,
	})
	if err != nil {
		ctl.log.Error().Err(err).Msg("Could not update dialog settings")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "Could not update dialog settings", "err": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (ctl *Controller) DeleteDialogSettings(c *gin.Context) {
	dialogSettingsId, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = ctl.q.DeleteDialogSettings(c, &dialogSettingsId)
	if err != nil {
		ctl.log.Error().Err(err).Msg("Could not delete dialog settings")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "Could not delete dialog settings", "err": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}
