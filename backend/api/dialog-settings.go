package api

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
)

type DialogSettings struct {
	ID                   *int64 `json:"id"`
	Name                 string `json:"name"`
	ColumnsNumber        *int64 `json:"columns_number"`
	IsCapacitySelectable *bool  `json:"is_capacity_selectable"`
	LocationID           int64  `json:"location_id"`
}

func (app *Application) createDialogSettings(c *gin.Context) {
	var dialogSettingsDTO DialogSettings
	err := c.BindJSON(&dialogSettingsDTO)
	if err != nil {
		app.log.Debug().Err(err).Msg("Could not parse dialog settings")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse dialog settings", "err": err.Error()})
		return
	}

	dialogSettings, err := app.q.CreateDialogSettings(c, db.CreateDialogSettingsParams{
		Name:                 &dialogSettingsDTO.Name,
		ColumnsNumber:        dialogSettingsDTO.ColumnsNumber,
		IsCapacitySelectable: dialogSettingsDTO.IsCapacitySelectable,
		LocationID:           dialogSettingsDTO.LocationID,
	})
	if err != nil {
		app.log.Error().Err(err).Msg("Could not create dialog settings")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "Could not create dialog settings", "err": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, dialogSettings)
}

func (app *Application) updateDialogSettings(c *gin.Context) {
	dialogSettingsId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	var dialogSettingsDTO DialogSettings
	err = c.BindJSON(&dialogSettingsDTO)
	if err != nil {
		app.log.Debug().Err(err).Msg("Could not parse dialog settings")
		c.JSON(http.StatusBadRequest, gin.H{"message": "Could not parse dialog settings", "err": err.Error()})
		return
	}

	err = app.q.UpdateDialogSettings(c, db.UpdateDialogSettingsParams{
		ID:                   &dialogSettingsId,
		Name:                 &dialogSettingsDTO.Name,
		ColumnsNumber:        dialogSettingsDTO.ColumnsNumber,
		IsCapacitySelectable: dialogSettingsDTO.IsCapacitySelectable,
	})
	if err != nil {
		app.log.Error().Err(err).Msg("Could not update dialog settings")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "Could not update dialog settings", "err": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (app *Application) deleteDialogSettings(c *gin.Context) {
	dialogSettingsId, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = app.q.DeleteDialogSettings(c, &dialogSettingsId)
	if err != nil {
		app.log.Error().Err(err).Msg("Could not delete dialog settings")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "Could not delete dialog settings", "err": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (app *Application) addDialogSettingsImage(c *gin.Context, dialogSettingsId int64) {
	app.extractAndSaveImage(c, func(q *db.Queries, fileName string, content []byte) (imageId *int64, err error) {
		if imageId, err = app.createImageInDB(fileName, content, q); err == nil {
			err = q.UpdateDialogSettingsImage(app.ctx, db.UpdateDialogSettingsImageParams{
				ID:               imageId,
				DialogSettingsID: &dialogSettingsId,
			})
		}
		return
	})
}
