package internal

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/casbin/casbin/v2"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/db"
	"strconv"
)

type UserHandler struct {
	Queries  *db.Queries
	DB       *sql.DB
	Ctx      context.Context
	Enforcer *casbin.Enforcer
}

func (h *UserHandler) Register(c *gin.Context) {
	var (
		user = struct {
			UID *string `json:"uid"`
		}{}
		err error
	)

	if err = c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	if user.UID == nil || *user.UID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "user cannot be created without a UID"})
		return
	}

	if err = h.Queries.CreateUser(h.Ctx, user.UID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if _, err = h.Enforcer.AddRoleForUser(*user.UID, "user"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "new user has been created"})
}

func (h *UserHandler) UpdateUserRootLocation(c *gin.Context) {
	var (
		locationId int64
		err        error
	)
	if locationId, err = strconv.ParseInt(c.Param("id"), 10, 64); err != nil {
		fmt.Printf("[ERROR] parseLocationId: %v\n", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	uid := c.GetString("tokenUID")
	user, err := h.Queries.GetUserByUID(h.Ctx, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err = h.Queries.UpdateUserRootLocation(h.Ctx, db.UpdateUserRootLocationParams{
		ID:                    user.ID,
		CurrentRootLocationID: &locationId,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user has been updated"})
}

func (h *UserHandler) DeleteUserLocation(c *gin.Context) {
	uid := c.GetString("tokenUID")
	user, err := h.Queries.GetUserByUID(h.Ctx, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err = h.Queries.UpdateUserRootLocation(h.Ctx, db.UpdateUserRootLocationParams{
		ID:                    user.ID,
		CurrentRootLocationID: nil,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if err = h.Queries.UpdateUserLocation(h.Ctx, db.UpdateUserLocationParams{
		ID:                user.ID,
		CurrentLocationID: nil,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user location has been deleted"})
}

func (h *UserHandler) UpdateUsername(c *gin.Context) {
	var user = struct {
		Username string `json:"username"`
	}{}

	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	uid := c.GetString("tokenUID")

	if err := h.Queries.UpdateUsername(h.Ctx, db.UpdateUsernameParams{
		Username: &user.Username,
		Uid:      &uid,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "Username updated"})
}

func (h *UserHandler) GetUserByUsername(c *gin.Context) {
	username := c.Param("username")

	log.Debug().Msgf("Get user by username: %s", username)

	user, err := h.Queries.GetUserByUsername(h.Ctx, &username)
	if err != nil {
		log.Debug().Msgf("User by username %s not found. Error: %v", username, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	if c.Request.Method == "HEAD" {
		c.Status(http.StatusOK)
	} else {
		c.JSON(http.StatusOK, user)
	}
}

func (h *UserHandler) GetUserByUID(c *gin.Context) {
	userUID := c.Query("userUID")

	log.Debug().Msgf("Get user by UID: %s", userUID)

	user, err := h.Queries.GetUserByUID(h.Ctx, &userUID)
	if err != nil {
		log.Debug().Msgf("User by UID %s not found. Error: %v", userUID, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, user)
}

func (h *UserHandler) DeleteUser(c *gin.Context) {
	uid := c.GetString("tokenUID")

	tx, err := h.DB.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}
	defer func() {
		if deferredErr := tx.Rollback(); deferredErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"msg": fmt.Sprintf("could not rollback a transaction: %v", deferredErr)})
			return
		}
	}()

	user, err := h.Queries.WithTx(tx).DeleteUser(h.Ctx, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if user.ImageID != nil {
		if err := h.Queries.WithTx(tx).DeleteImage(c, *user.ImageID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
			return
		}
	}

	isUserDeleted, err := h.Enforcer.DeleteUser(uid)
	if err != nil || !isUserDeleted {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": "Could not delete user roles/privileges"})
		return
	}

	err = tx.Commit()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user has been deleted"})
}
