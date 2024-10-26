package friendship

import (
	"database/sql"
	"errors"
	"firebase.google.com/go/messaging"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/api/common"
	"party-time/db"
	"strconv"
	"strings"
)

type Controller struct {
	q   *db.Queries
	log *zerolog.Logger
	msg *messaging.Client
}

func NewController(q *db.Queries, log *zerolog.Logger, msg *messaging.Client) *Controller {
	return &Controller{q: q, log: log, msg: msg}
}

func (ctl *Controller) GetQ() *db.Queries {
	return ctl.q
}

func (ctl *Controller) GetLog() *zerolog.Logger {
	return ctl.log
}

func (ctl *Controller) GetMsg() *messaging.Client {
	return ctl.msg
}

func (ctl *Controller) GetFriendships(c *gin.Context) {
	user, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	username := c.Query("username")
	if len(username) > 0 {
		friendship, err := getFriendshipByUsername(ctl, username, user, c)
		if err != nil {
			c.Status(http.StatusInternalServerError)
			return
		}
		if err == nil && friendship == nil {
			c.Status(http.StatusNoContent)
			return
		}

		c.JSON(http.StatusOK, friendship)
		return
	}
	status := c.Query("status")
	if len(status) == 0 {
		ctl.log.Debug().Ctx(c).Msg("Empty friendship status")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Status cannot be empty"})
		return
	}
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

	if status == "requested" {
		friendshipRequests, err := ctl.q.GetFriendshipRequestsByUser(c, db.GetFriendshipRequestsByUserParams{
			User2ID: user.ID,
			Offset:  int32(offset),
			Limit:   int32(limit),
		})
		if err != nil {
			ctl.log.Debug().Ctx(c).Err(err).Msg("Could not get friendship requests")
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, friendshipRequests)
		return
	} else if status == "accepted" {
		friends, err := ctl.q.GetFriendshipsByUser(c, db.GetFriendshipsByUserParams{
			Userid: user.ID,
			Offset: int32(offset),
			Limit:  int32(limit),
		})
		if err != nil {
			ctl.log.Debug().Ctx(c).Err(err).Msg("Could not get friendships")
			c.JSON(http.StatusInternalServerError, err.Error())
			return
		}

		username := c.Query("username")
		if len(username) > 0 {
			friendsNames := make([]string, 0)

			for _, f := range friends {
				if strings.Contains(f.Username.(string), username) {
					friendsNames = append(friendsNames, f.Username.(string))
				}
			}

			c.JSON(http.StatusOK, friendsNames)
			return
		}

		c.JSON(http.StatusOK, friends)
		return
	}

	ctl.log.Debug().Ctx(c).Msg("Unknown friendship status")
	c.JSON(http.StatusBadRequest, gin.H{"message": "Friendship status unrecognized"})
}

func (ctl *Controller) GetFriendshipsCount(c *gin.Context) {
	friendshipStatus := c.Query("status")
	if len(friendshipStatus) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "FriendshipStatus cannot be empty"})
		return
	}

	uid := c.Query("userUID")
	if len(uid) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "FriendshipStatus cannot be empty"})
		return
	}

	user, err := ctl.q.GetUserByUID(c, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var (
		friendshipsCount int64
	)
	if friendshipStatus == "requested" {
		friendshipsCount, err = ctl.q.GetFriendshipRequestsCountByUser(c, user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	} else if friendshipStatus == "accepted" {
		friendshipsCount, err = ctl.q.GetFriendshipsCountByUser(c, user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, err.Error())
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"count": friendshipsCount})
}

func (ctl *Controller) CreateFriendshipRequest(c *gin.Context) {
	userFrom, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	requestUser := struct {
		Username *string `json:"username"`
	}{}
	err = c.BindJSON(&requestUser)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userTo, err := ctl.q.GetUserByUsername(c, requestUser.Username)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User not found"})
		return
	}

	if userTo.ID == userFrom.ID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "friendship request cannot be sent to the person same as sender"})
		return
	}

	friendship, err := ctl.q.GetFriendshipByUserIds(c, db.GetFriendshipByUserIdsParams{
		User1ID: userFrom.ID,
		User2ID: userTo.ID,
	})
	if err != nil {
		err = ctl.q.CreateFriendshipRequest(c, db.CreateFriendshipRequestParams{
			User1ID: userFrom.ID,
			User2ID: userTo.ID,
		})
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		go sendFriendshipRequestNotification(ctl, c, userFrom, userTo)

		c.Status(http.StatusOK)
		return
	}

	if friendship.Status == "accepted" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Can't send friendship request to a friend"})
		return
	}

	err = ctl.q.UpdateFriendship(c, db.UpdateFriendshipParams{
		ID:       friendship.ID,
		User1ID:  userFrom.ID,
		User2ID:  userTo.ID,
		StatusID: 1,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	go sendFriendshipRequestNotification(ctl, c, userFrom, userTo)

	c.Status(http.StatusOK)
}

func (ctl *Controller) UpdateFriendship(c *gin.Context) {
	friendship := struct {
		Status string `json:"status"`
	}{}
	err := c.BindJSON(&friendship)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	friendshipID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	friendshipFromDB, err := ctl.q.GetFriendshipById(c, friendshipID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No friendship found"})
		return
	}

	friendshipStatusId, err := ctl.q.GetFriendshipStatusId(c, friendship.Status)
	if err != nil {
		fmt.Print(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	updateSender, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var updateReceiverID int64
	if friendshipFromDB.User1ID == updateSender.ID {
		updateReceiverID = friendshipFromDB.User2ID
	} else {
		updateReceiverID = friendshipFromDB.User1ID
	}

	err = ctl.q.UpdateFriendship(c, db.UpdateFriendshipParams{
		ID:       friendshipID,
		StatusID: friendshipStatusId,
		User1ID:  updateSender.ID,
		User2ID:  updateReceiverID,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (ctl *Controller) DeleteFriendship(c *gin.Context) {
	friendshipID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = ctl.q.DeleteFriendshipById(c, friendshipID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func sendFriendshipRequestNotification(
	ctl common.MessagingController, c *gin.Context, userFrom db.GetUserByUIDRow, userTo db.User,
) {
	hasUserTopic, err := ctl.GetQ().HasUserTopic(c, userTo.ID)
	if err != nil {
		log.Err(err).Msg("Failed to check if user has a friendship request notification topic")
		return
	}

	if userTo.FcmToken != nil && hasUserTopic {
		response, err := ctl.GetMsg().Send(c, &messaging.Message{
			Notification: &messaging.Notification{
				Title: "New friend request",
				Body:  *userFrom.Username + " sent you a friend request",
			},
			Data: map[string]string{
				"view": "friendship-requests",
			},
			Token: *userTo.FcmToken,
		})
		if err != nil {
			log.Err(err).Msg("Failed to write to friendshipRequestNotification topic")
			return
		}
		log.Debug().Msgf("Successfully sent friendship request message: %s", response)
	}

}

func getFriendshipByUsername(
	ctl common.Controller, username string, userFromContext db.GetUserByUIDRow, c *gin.Context,
) (*db.GetFriendshipByUserIdsRow, error) {
	if len(username) == 0 {
		return nil, errors.New("username cannot be empty")
	}

	user, err := ctl.GetQ().GetUserByUsername(c, &username)
	if err != nil {
		log.Debug().Msg("can't get user by username=" + username)
		return nil, errors.New("can't get user by username " + username)
	}

	friendship, err := ctl.GetQ().GetFriendshipByUserIds(c, db.GetFriendshipByUserIdsParams{
		User1ID: user.ID,
		User2ID: userFromContext.ID,
	})
	if err != nil && errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		log.Debug().Msg("Can't get friendship by 2 user IDs")
		return nil, errors.New("can't get friendship by 2 user IDs")
	}

	return &friendship, nil
}
