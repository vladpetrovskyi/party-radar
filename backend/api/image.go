package api

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
	"strconv"
)

func (app *Application) createImage(c *gin.Context) {
	userIdString := c.Query("userId")
	dialogSettingsIdString := c.Query("dialogSettingsId")
	if len(userIdString) > 0 {
		userId, err := strconv.ParseInt(userIdString, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User ID must be numeric"})
			return
		}
		app.addUserImage(c, userId)
		return
	} else if len(dialogSettingsIdString) > 0 {
		dialogSettingsId, err := strconv.ParseInt(dialogSettingsIdString, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User ID must be numeric"})
			return
		}

		app.addDialogSettingsImage(c, dialogSettingsId)
		return
	}

	c.JSON(http.StatusBadRequest, gin.H{"error": "No dependent entity provided, image cannot be saved"})
}

func (app *Application) getImage(c *gin.Context) {
	imageID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	image, err := app.q.GetImage(app.ctx, &imageID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}

	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%h", image.FileName))
	c.Data(http.StatusOK, "application/octet-stream", image.Content)
}

func (app *Application) checkImageExists(c *gin.Context) {
	imageID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	image, err := app.q.GetImage(app.ctx, &imageID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}
	if len(image.Content) == 0 {
		c.Status(http.StatusNotFound)
		return
	}

	c.Status(http.StatusOK)
}

func (app *Application) updateImage(c *gin.Context) {
	app.extractAndSaveImage(c, func(q *db.Queries, fileName string, content []byte) (*int64, error) {
		imageID, err := app.readIDParam(c)
		if err != nil {
			return nil, err
		}

		err = q.UpdateImage(app.ctx, db.UpdateImageParams{
			ID:       &imageID,
			FileName: fileName,
			Content:  content,
		})
		return &imageID, err
	})
}

func (app *Application) addUserImage(c *gin.Context, userId int64) {
	app.extractAndSaveImage(c, func(q *db.Queries, fileName string, content []byte) (imageID *int64, err error) {
		if imageID, err = app.createImageInDB(fileName, content, q); err == nil {
			err = q.UpdateUserImageId(app.ctx, db.UpdateUserImageIdParams{
				ID:     imageID,
				UserID: &userId,
			})
		}
		return
	})
}

func (app *Application) extractAndSaveImage(c *gin.Context, saveImage func(q *db.Queries, fileName string, content []byte) (*int64, error)) {
	tx, err := app.db.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not begin the transaction: %v", err))
		return
	}
	defer tx.Rollback()

	img, err := c.FormFile("imageFile")
	if err != nil {
		c.JSON(http.StatusBadRequest, nil)
		return
	}
	file, err := img.Open()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": fmt.Sprintf("createImageInDB, could not open file: %v", err)})
		return
	}
	defer func() {
		if deferredErr := file.Close(); deferredErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"msg": fmt.Sprintf("could not save image: %v", deferredErr)})
			return
		}
	}()

	fileBytes := make([]byte, img.Size)
	_, err = file.Read(fileBytes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": fmt.Sprintf("createImageInDB, could not read file into byte array: %v", err)})
		return
	}

	q := app.q.WithTx(tx)

	imageID, err := saveImage(q, img.Filename, fileBytes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not save image and dependant entity: %v", err))
		return
	}

	if err := tx.Commit(); err != nil {
		c.AbortWithStatusJSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not commit transaction: %w", err))
		return
	}

	c.JSON(http.StatusOK, gin.H{"id": imageID})
}

func (app *Application) createImageInDB(fileName string, content []byte, q *db.Queries) (*int64, error) {
	if q == nil {
		q = app.q
	}

	imageId, err := q.CreateImage(app.ctx, db.CreateImageParams{
		FileName: fileName,
		Content:  content,
	})
	if err != nil {
		return nil, err
	}

	return imageId, nil
}

func (app *Application) deleteImage(c *gin.Context) {
	imageID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = app.q.DeleteImage(c, &imageID)
	if err != nil {
		app.log.Error().Err(err).Msg("Could not delete image by ID")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "deleteImage, could not delete image"})
		return
	}

	c.Status(http.StatusOK)
}
