package user

import (
	"context"
	"database/sql"
	"errors"
	"github.com/casbin/casbin/v2"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/api/common"
	"party-time/db"
	"strconv"
)

type Controller struct {
	q     *db.Queries
	log   *zerolog.Logger
	db    *sql.DB
	n4cer *casbin.Enforcer
}

func NewController(q *db.Queries, log *zerolog.Logger, db *sql.DB, n4cer *casbin.Enforcer) *Controller {
	return &Controller{q: q, log: log, db: db, n4cer: n4cer}
}

func DeleteUserLocations(q *db.Queries, c context.Context, userID int64) (err error) {
	if err = q.UpdateUserRootLocation(c, db.UpdateUserRootLocationParams{
		ID:                    userID,
		CurrentRootLocationID: nil,
	}); err != nil {
		return
	}

	if err = q.UpdateUserLocation(c, db.UpdateUserLocationParams{
		ID:                userID,
		CurrentLocationID: nil,
	}); err != nil {
		return
	}

	return
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

func (ctl *Controller) Register(c *gin.Context) {
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

	if err = ctl.q.CreateUser(c, db.CreateUserParams{
		Uid:      user.UID,
		FcmToken: user.FCMToken,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if _, err = ctl.n4cer.AddRoleForUser(*user.UID, "user"); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "new user has been created"})
}

func (ctl *Controller) UpdateUserRootLocation(c *gin.Context) {
	locationID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err = ctl.q.UpdateUserRootLocation(c, db.UpdateUserRootLocationParams{
		ID:                    user.ID,
		CurrentRootLocationID: &locationID,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user has been updated"})
}

// DeleteUserLocation Deprecated
// Deleting current user root location and posting and update should both happen in backend
func (ctl *Controller) DeleteUserLocation(c *gin.Context) {
	user, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err = ctl.q.UpdateUserRootLocation(c, db.UpdateUserRootLocationParams{
		ID:                    user.ID,
		CurrentRootLocationID: nil,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	if err = ctl.q.UpdateUserLocation(c, db.UpdateUserLocationParams{
		ID:                user.ID,
		CurrentLocationID: nil,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user location has been deleted"})
}

func (ctl *Controller) DeleteUserLocationV2(c *gin.Context) {
	user, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if user.CurrentRootLocationID == nil {
		c.JSON(http.StatusAlreadyReported, gin.H{"msg": "user location has already been deleted"})
		return
	}

	if err := DeleteUserLocation(ctl, user.ID, user.CurrentRootLocationID, c); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "user location has been deleted"})
}

func DeleteUserLocation(ctl common.DBController, userID int64, currentRootLocationID *int64, c context.Context) error {
	if currentRootLocationID == nil {
		return errors.New("user root location id is nil and cannot be deleted")
	}
	if err := DeleteUserLocations(ctl.GetQ(), c, userID); err != nil {
		return err
	}

	if err := CreatePostForUser(ctl, c, userID, *currentRootLocationID, "end", nil); err != nil {
		return err
	}

	return nil
}

func (ctl *Controller) UpdateUsername(c *gin.Context) {
	var user = struct {
		Username string `json:"username"`
	}{}

	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	uid := c.GetString("tokenUID")

	if err := ctl.q.UpdateUsername(c, db.UpdateUsernameParams{
		Username: &user.Username,
		Uid:      &uid,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"msg": "Username updated"})
}

func (ctl *Controller) GetUser(c *gin.Context) {
	userUID := c.Query("userUID")
	if len(userUID) != 0 {
		ctl.log.Debug().Msgf("Get user by UID: %s", userUID)

		user, err := ctl.q.GetUserByUID(c, &userUID)
		if err != nil {
			ctl.log.Debug().Msgf("User by UID %s not found. Error: %v", userUID, err)
			c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
			return
		}

		c.JSON(http.StatusOK, user)
		return
	}

	username := c.Query("username")
	ctl.log.Debug().Msgf("Get user by username: %s", username)
	username = "%" + username + "%"

	offset, err := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if err != nil {
		ctl.log.Debug().Ctx(c).Msg("Offset is not parsable")
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	limit, err := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if err != nil {
		ctl.log.Debug().Ctx(c).Msg("Limit is not parsable")
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	contextUser, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	userList, err := ctl.q.GetUsersByUsername(c, db.GetUsersByUsernameParams{
		Username: &username,
		Limit:    int32(limit),
		Offset:   int32(offset),
		ID:       contextUser.ID,
	})
	if err != nil {
		ctl.log.Debug().Msgf("User by username %s not found. Error: %v", username, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, userList)
}

func (ctl *Controller) DeleteUser(c *gin.Context) {
	uid := c.GetString("tokenUID")

	tx, err := ctl.db.Begin()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}
	defer tx.Rollback()

	_, err = ctl.q.WithTx(tx).DeleteUser(c, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	isUserDeleted, err := ctl.n4cer.DeleteUser(uid)
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

func (ctl *Controller) UpdateUserFCMToken(c *gin.Context) {
	var user = struct {
		FCMToken *string `json:"fcm_token"`
	}{}

	if err := c.BindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, err.Error())
		return
	}

	uid := c.GetString("tokenUID")

	if err := ctl.q.UpdateFCMToken(c, db.UpdateFCMTokenParams{
		Uid:      &uid,
		FcmToken: user.FCMToken,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"msg": err.Error()})
		return
	}

	ctl.log.Debug().Msgf("Updated user %s with new FCM token %v", uid, *user.FCMToken)

	c.JSON(http.StatusOK, gin.H{"msg": "FCM token updated"})
}

func (ctl *Controller) GetUserByUsername(c *gin.Context) {
	username := c.Param("username")

	ctl.log.Debug().Msgf("Get user by username: %s", username)

	user, err := ctl.q.GetUserByUsername(c, &username)
	if err != nil {
		ctl.log.Debug().Msgf("User by username %s not found. Error: %v", username, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	if c.Request.Method == "HEAD" {
		c.Status(http.StatusOK)
	} else {
		c.JSON(http.StatusOK, user)
	}
}

func (ctl *Controller) GetUserByUID(c *gin.Context) {
	userUID := c.Query("userUID")

	ctl.log.Debug().Msgf("Get user by UID: %s", userUID)

	user, err := ctl.q.GetUserByUID(c, &userUID)
	if err != nil {
		ctl.log.Debug().Msgf("User by UID %s not found. Error: %v", userUID, err)
		c.JSON(http.StatusNotFound, gin.H{"msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, user)
}

func CreatePostForUser(
	ctl common.DBController, c context.Context, userID int64, locationID int64, postType string, capacity *int64,
) error {
	postTypeId, err := ctl.GetQ().GetPostTypeId(c, postType)
	if err != nil {
		log.Err(err)
		return err
	}

	tx, err := ctl.GetDB().BeginTx(c, nil)
	if err != nil {
		log.Err(err).Msg("Failed to begin a transaction while creating a new post")
		return err
	}
	defer tx.Rollback()

	if err = ctl.GetQ().WithTx(tx).CreatePost(c, db.CreatePostParams{
		UserID:     userID,
		LocationID: locationID,
		PostTypeID: postTypeId,
		Capacity:   capacity,
	}); err != nil {
		log.Err(err).Msg("Failed to create post")
		return err
	}

	if err = ctl.GetQ().WithTx(tx).UpdateUserLocation(c, db.UpdateUserLocationParams{
		ID:                userID,
		CurrentLocationID: &locationID,
	}); err != nil {
		log.Err(err).Msg("Failed to update user location while creating a new post")
		return err
	}

	if err = tx.Commit(); err != nil {
		log.Err(err).Msg("Failed to commit new post to DB")
		return err
	}

	return nil
}
