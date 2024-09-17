package api

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
	"strconv"
)

func (app *Application) register(c *gin.Context) {
	var (
		user = struct {
			UID      *string `json:"uid"`
			FCMToken *string `json:"fcm_token"`
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

	if err = app.q.CreateUser(app.ctx, db.CreateUserParams{
		Uid:      user.UID,
		FcmToken: user.FCMToken,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if _, err = app.n4cer.AddRoleForUser(*user.UID, "user"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "new user has been created"})
}

func (app *Application) updateUserRootLocation(c *gin.Context) {
	locationID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err = app.q.UpdateUserRootLocation(app.ctx, db.UpdateUserRootLocationParams{
		ID:                    user.ID,
		CurrentRootLocationID: &locationID,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user has been updated"})
}

// Deprecated
// Deleting current user root location and posting and update should both happen in backend
func (app *Application) deleteUserLocation(c *gin.Context) {
	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err = app.q.UpdateUserRootLocation(app.ctx, db.UpdateUserRootLocationParams{
		ID:                    user.ID,
		CurrentRootLocationID: nil,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if err = app.q.UpdateUserLocation(app.ctx, db.UpdateUserLocationParams{
		ID:                user.ID,
		CurrentLocationID: nil,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user location has been deleted"})
}

func (app *Application) deleteUserLocationV2(c *gin.Context) {
	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if user.CurrentRootLocationID == nil {
		c.JSON(http.StatusAlreadyReported, gin.H{"msg": "user location has already been deleted"})
		return
	}

	err = app.deleteUserLocations(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	err = app.createPostForUser(user, *user.CurrentRootLocationID, "end", nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user location has been deleted"})
}

func (app *Application) deleteUserLocations(user db.User) (err error) {
	if err = app.q.UpdateUserRootLocation(app.ctx, db.UpdateUserRootLocationParams{
		ID:                    user.ID,
		CurrentRootLocationID: nil,
	}); err != nil {
		return
	}

	if err = app.q.UpdateUserLocation(app.ctx, db.UpdateUserLocationParams{
		ID:                user.ID,
		CurrentLocationID: nil,
	}); err != nil {
		return
	}

	return
}

func (app *Application) updateUsername(c *gin.Context) {
	var user = struct {
		Username string `json:"username"`
	}{}

	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	uid := c.GetString("tokenUID")

	if err := app.q.UpdateUsername(app.ctx, db.UpdateUsernameParams{
		Username: &user.Username,
		Uid:      &uid,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "Username updated"})
}

func (app *Application) getUser(c *gin.Context) {
	userUID := c.Query("userUID")
	if len(userUID) != 0 {
		app.log.Debug().Msgf("Get user by UID: %s", userUID)

		user, err := app.q.GetUserByUID(app.ctx, &userUID)
		if err != nil {
			app.log.Debug().Msgf("User by UID %s not found. Error: %v", userUID, err)
			c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
			return
		}

		c.JSON(http.StatusOK, user)
		return
	}

	username := c.Query("username")
	app.log.Debug().Msgf("Get user by username: %s", username)
	username = "%" + username + "%"

	offset, err := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if err != nil {
		app.log.Debug().Ctx(c).Msg("Offset is not parsable")
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	limit, err := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if err != nil {
		app.log.Debug().Ctx(c).Msg("Limit is not parsable")
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	contextUser, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	userList, err := app.q.GetUsersByUsername(app.ctx, db.GetUsersByUsernameParams{
		Username: &username,
		Limit:    int32(limit),
		Offset:   int32(offset),
		ID:       contextUser.ID,
	})
	if err != nil {
		app.log.Debug().Msgf("User by username %s not found. Error: %v", username, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, userList)
}

func (app *Application) deleteUser(c *gin.Context) {
	uid := c.GetString("tokenUID")

	tx, err := app.db.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}
	defer tx.Rollback()

	_, err = app.q.WithTx(tx).DeleteUser(app.ctx, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	isUserDeleted, err := app.n4cer.DeleteUser(uid)
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

func (app *Application) updateUserFCMToken(c *gin.Context) {
	var user = struct {
		FCMToken *string `json:"fcm_token"`
	}{}

	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	uid := c.GetString("tokenUID")

	if err := app.q.UpdateFCMToken(app.ctx, db.UpdateFCMTokenParams{
		Uid:      &uid,
		FcmToken: user.FCMToken,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	app.log.Debug().Msgf("Updated user %s with new FCM token %v", uid, *user.FCMToken)

	c.JSON(http.StatusOK, gin.H{"msg": "FCM token updated"})
}

func (app *Application) getUserByUsername(c *gin.Context) {
	username := c.Param("username")

	app.log.Debug().Msgf("Get user by username: %s", username)

	user, err := app.q.GetUserByUsername(app.ctx, &username)
	if err != nil {
		app.log.Debug().Msgf("User by username %s not found. Error: %v", username, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	if c.Request.Method == "HEAD" {
		c.Status(http.StatusOK)
	} else {
		c.JSON(http.StatusOK, user)
	}
}

func (app *Application) getUserByUID(c *gin.Context) {
	userUID := c.Query("userUID")

	app.log.Debug().Msgf("Get user by UID: %s", userUID)

	user, err := app.q.GetUserByUID(app.ctx, &userUID)
	if err != nil {
		app.log.Debug().Msgf("User by UID %s not found. Error: %v", userUID, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, user)
}
