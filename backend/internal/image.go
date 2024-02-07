package internal

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
	"strconv"
)

type ImageHandler struct {
	Queries *db.Queries
	DB      *sql.DB
	Ctx     context.Context
}

func (h *ImageHandler) CreateImage(c *gin.Context) {
	userIdString := c.Query("userId")
	dialogSettingsIdString := c.Query("dialogSettingsId")
	if len(userIdString) > 0 {
		userId, err := strconv.ParseInt(userIdString, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User ID must be numeric"})
			return
		}
		h.addUserImage(c, userId)
		return
	} else if len(dialogSettingsIdString) > 0 {
		dialogSettingsId, err := strconv.ParseInt(dialogSettingsIdString, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User ID must be numeric"})
			return
		}

		h.addDialogSettingsImage(c, dialogSettingsId)
		return
	}

	c.JSON(http.StatusBadRequest, gin.H{"error": "No dependent entity provided, image cannot be saved"})
	return
}

func (h *ImageHandler) GetImage(c *gin.Context) {
	imageId, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Incorrect ID"})
		return
	}

	image, err := h.Queries.GetImage(h.Ctx, imageId)
	if err != nil {
		c.JSON(http.StatusInternalServerError, err)
		return
	}

	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%h", image.FileName))
	c.Data(http.StatusOK, "application/octet-stream", image.Content)
}

func (h *ImageHandler) CheckImageExists(c *gin.Context) {
	imageId, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Incorrect ID"})
		return
	}

	image, err := h.Queries.GetImage(h.Ctx, imageId)
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

func (h *ImageHandler) UpdateImage(c *gin.Context) {
	h.extractAndSaveImage(c, func(q *db.Queries, fileName string, content []byte) (err error) {
		imageId, err := strconv.ParseInt(c.Param("id"), 10, 64)
		if err != nil {
			return err
		}
		err = q.UpdateImage(h.Ctx, db.UpdateImageParams{
			ID:       imageId,
			FileName: fileName,
			Content:  content,
		})
		return err
	})
}

func (h *ImageHandler) addDialogSettingsImage(c *gin.Context, dialogSettingsId int64) {
	h.extractAndSaveImage(c, func(q *db.Queries, fileName string, content []byte) (err error) {
		var imageId *int64
		if imageId, err = h.createImageInDB(fileName, content, q); err == nil {
			err = q.UpdateDialogSettingsImage(h.Ctx, db.UpdateDialogSettingsImageParams{
				ID:      dialogSettingsId,
				ImageID: imageId,
			})
		}

		return err
	})
}

func (h *ImageHandler) addUserImage(c *gin.Context, userId int64) {
	h.extractAndSaveImage(c, func(q *db.Queries, fileName string, content []byte) (err error) {
		var imageId *int64
		if imageId, err = h.createImageInDB(fileName, content, q); err == nil {
			err = q.UpdateUserImageId(h.Ctx, db.UpdateUserImageIdParams{
				ID:      userId,
				ImageID: imageId,
			})
		}

		return err
	})
}

func (h *ImageHandler) extractAndSaveImage(c *gin.Context, saveImage func(q *db.Queries, fileName string, content []byte) error) {
	tx, err := h.DB.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not begin the transaction: %v", err))
		return
	}
	defer func() {
		if deferredErr := tx.Rollback(); deferredErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"msg": fmt.Sprintf("could not rollback a transaction: %v", deferredErr)})
			return
		}
	}()

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

	q := h.Queries.WithTx(tx)

	err = saveImage(q, img.Filename, fileBytes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not save image and dependant entity: %v", err))
		return
	}

	if err := tx.Commit(); err != nil {
		c.AbortWithStatusJSON(http.StatusInternalServerError, fmt.Sprintf("createImageInDB, could not commit transaction: %w", err))
		return
	}

	c.JSON(http.StatusOK, nil)
}

func (h *ImageHandler) createImageInDB(fileName string, content []byte, q *db.Queries) (*int64, error) {
	if q == nil {
		q = h.Queries
	}

	imageId, err := q.CreateImage(h.Ctx, db.CreateImageParams{
		FileName: fileName,
		Content:  content,
	})
	if err != nil {
		return nil, err
	}

	return &imageId, nil
}
