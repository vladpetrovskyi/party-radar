package internal

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/casbin/casbin/v2"
	"github.com/gin-gonic/gin"
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
			UID   *string `json:"uid"`
			Email *string `json:"email"`
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

	if err = h.Queries.CreateUser(h.Ctx, db.CreateUserParams{
		Uid:   user.UID,
		Email: user.Email,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if _, err = h.Enforcer.AddRoleForUser(*user.UID, "user"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "new user has been created"})
}

func (h *UserHandler) UpdateUser(c *gin.Context) {
	var (
		user = struct {
			Username *string `json:"username"`
			Email    *string `json:"email"`
		}{}
		err error
	)
	if err = c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	uid := c.GetString("tokenUID")

	if err = h.Queries.UpdateUser(h.Ctx, db.UpdateUserParams{
		Username: user.Username,
		Email:    user.Email,
		Uid:      &uid,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user has been updated"})
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

	user, err := h.Queries.GetUserByUsername(h.Ctx, &username)
	if err != nil {
		c.JSON(http.StatusNotFound, nil)
		return
	}

	if c.Request.Method == "HEAD" {
		c.JSON(200, nil)
	} else {
		c.JSON(200, user)
	}
}

func (h *UserHandler) GetUserByUID(c *gin.Context) {
	userUID := c.Query("userUID")

	user, err := h.Queries.GetUserByUID(h.Ctx, &userUID)
	if err != nil {
		c.JSON(http.StatusNotFound, nil)
		return
	}

	if c.Request.Method == "HEAD" {
		c.JSON(200, nil)
	} else {
		c.JSON(200, user)
	}
}
