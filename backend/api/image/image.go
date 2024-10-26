package image

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"net/http"
	"party-time/api/common"
	"party-time/db"
	"strconv"
)

type Controller struct {
	log *zerolog.Logger
	db  *sql.DB
	q   *db.Queries
}

func NewController(log *zerolog.Logger, db *sql.DB, q *db.Queries) *Controller {
	return &Controller{
		log: log,
		db:  db,
		q:   q,
	}
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

func (ctl *Controller) CreateImage(c *gin.Context) {
	userIdString := c.Query("userId")
	dialogSettingsIdString := c.Query("dialogSettingsId")
	if len(userIdString) > 0 {
		userId, err := strconv.ParseInt(userIdString, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User ID must be numeric"})
			return
		}
		addUserImage(ctl, c, userId)
		return
	} else if len(dialogSettingsIdString) > 0 {
		dialogSettingsId, err := strconv.ParseInt(dialogSettingsIdString, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User ID must be numeric"})
			return
		}

		addDialogSettingsImage(ctl, c, dialogSettingsId)
		return
	}

	c.JSON(http.StatusBadRequest, gin.H{"error": "No dependent entity provided, image cannot be saved"})
}

func (ctl *Controller) GetImage(c *gin.Context) {
	imageID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	image, err := ctl.q.GetImage(c, &imageID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}

	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%h", image.FileName))
	c.Data(http.StatusOK, "application/octet-stream", image.Content)
}

func (ctl *Controller) CheckImageExists(c *gin.Context) {
	imageID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	image, err := ctl.q.GetImage(c, &imageID)
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

func (ctl *Controller) UpdateImage(c *gin.Context) {
	extractAndSaveImage(ctl, c, func(q *db.Queries, fileName string, content []byte) (*int64, error) {
		imageID, err := common.ReadIDParam(c)
		if err != nil {
			return nil, err
		}

		err = q.UpdateImage(c, db.UpdateImageParams{
			ID:       &imageID,
			FileName: fileName,
			Content:  content,
		})
		return &imageID, err
	})
}

func (ctl *Controller) DeleteImage(c *gin.Context) {
	imageID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = ctl.q.DeleteImage(c, &imageID)
	if err != nil {
		ctl.log.Error().Err(err).Msg("Could not delete image by ID")
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "DeleteImage, could not delete image"})
		return
	}

	c.Status(http.StatusOK)
}

func addUserImage(ctl *Controller, c *gin.Context, userId int64) {
	extractAndSaveImage(ctl, c, func(q *db.Queries, fileName string, content []byte) (imageID *int64, err error) {
		if imageID, err = createImageInDB(ctl.q, c, fileName, content); err == nil {
			err = q.UpdateUserImageId(c, db.UpdateUserImageIdParams{
				ID:     imageID,
				UserID: &userId,
			})
		}
		return
	})
}

func extractAndSaveImage(ctl common.DBController, c *gin.Context, saveImage func(q *db.Queries, fileName string, content []byte) (*int64, error)) {
	tx, err := ctl.GetDB().Begin()
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

	qTx := ctl.GetQ().WithTx(tx)

	imageID, err := saveImage(qTx, img.Filename, fileBytes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not save image and dependant entity: %v", err))
		return
	}

	if err := tx.Commit(); err != nil {
		c.AbortWithStatusJSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not commit transaction: %v", err))
		return
	}

	c.JSON(http.StatusOK, gin.H{"id": imageID})
}

func createImageInDB(q *db.Queries, ctx context.Context, fileName string, content []byte) (*int64, error) {
	imageId, err := q.CreateImage(ctx, db.CreateImageParams{
		FileName: fileName,
		Content:  content,
	})
	if err != nil {
		return nil, err
	}

	return imageId, nil
}

func addDialogSettingsImage(ctl common.DBController, c *gin.Context, dialogSettingsId int64) {
	extractAndSaveImage(ctl, c, func(q *db.Queries, fileName string, content []byte) (imageId *int64, err error) {
		if imageId, err = createImageInDB(ctl.GetQ(), c, fileName, content); err == nil {
			err = q.UpdateDialogSettingsImage(c, db.UpdateDialogSettingsImageParams{
				ID:               imageId,
				DialogSettingsID: &dialogSettingsId,
			})
		}
		return
	})
}
