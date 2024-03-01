package api

import (
	"firebase.google.com/go/messaging"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/db"
	"strconv"
	"strings"
)

func (app *Application) getFriendships(c *gin.Context) {
	status := c.Query("status")
	if len(status) == 0 {
		log.Debug().Ctx(c).Msg("Empty friendship status")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Status cannot be empty"})
		return
	}
	offset, err := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if err != nil {
		log.Debug().Ctx(c).Msg("Offset is not parsable")
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	limit, err := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if err != nil {
		log.Debug().Ctx(c).Msg("Limit is not parsable")
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if status == "requested" {
		friendshipRequests, err := app.q.GetFriendshipRequestsByUser(app.ctx, db.GetFriendshipRequestsByUserParams{
			User2ID: user.ID,
			Offset:  int32(offset),
			Limit:   int32(limit),
		})
		if err != nil {
			log.Debug().Ctx(c).Err(err).Msg("Could not get friendship requests")
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, friendshipRequests)
		return
	} else if status == "accepted" {
		friends, err := app.q.GetFriendshipsByUser(app.ctx, db.GetFriendshipsByUserParams{
			Userid: user.ID,
			Offset: int32(offset),
			Limit:  int32(limit),
		})
		if err != nil {
			log.Debug().Ctx(c).Err(err).Msg("Could not get friendships")
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

	log.Debug().Ctx(c).Msg("Unknown friendship status")
	c.JSON(http.StatusBadRequest, gin.H{"message": "Friendship status unrecognized"})
}

func (app *Application) getFriendshipsCount(c *gin.Context) {
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

	user, err := app.q.GetUserByUID(app.ctx, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var (
		friendshipsCount int64
	)
	if friendshipStatus == "requested" {
		friendshipsCount, err = app.q.GetFriendshipRequestsCountByUser(app.ctx, user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	} else if friendshipStatus == "accepted" {
		friendshipsCount, err = app.q.GetFriendshipsCountByUser(app.ctx, user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, err.Error())
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"count": friendshipsCount})
}

func (app *Application) createFriendshipRequest(c *gin.Context) {
	userFrom, err := app.getUserFromContext(c)
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

	userTo, err := app.q.GetUserByUsername(app.ctx, requestUser.Username)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User not found"})
		return
	}

	if userTo.ID == userFrom.ID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "friendship request cannot be sent to the person same as sender"})
		return
	}

	friendship, err := app.q.GetFriendshipByUserIds(c, db.GetFriendshipByUserIdsParams{
		User1ID: userFrom.ID,
		User2ID: userTo.ID,
	})
	if err != nil {
		err = app.q.CreateFriendshipRequest(app.ctx, db.CreateFriendshipRequestParams{
			User1ID: userFrom.ID,
			User2ID: userTo.ID,
		})
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		go app.sendFriendshipRequestNotification(userFrom, userTo)

		c.Status(http.StatusOK)
		return
	}

	if friendship.Status == "accepted" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Can't send friendship request to a friend"})
		return
	}

	err = app.q.UpdateFriendship(app.ctx, db.UpdateFriendshipParams{
		ID:       friendship.ID,
		User1ID:  userFrom.ID,
		User2ID:  userTo.ID,
		StatusID: 1,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	go app.sendFriendshipRequestNotification(userFrom, userTo)

	c.Status(http.StatusOK)
}

func (app *Application) sendFriendshipRequestNotification(userFrom db.User, userTo db.User) {
	hasUserTopic, err := app.q.HasUserTopic(app.ctx, userTo.ID)
	if err != nil {
		app.log.Err(err)
		return
	}

	if userTo.FcmToken != nil && hasUserTopic {
		response, err := app.msg.Send(app.ctx, &messaging.Message{
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
			app.log.Err(err)
			return
		}
		app.log.Debug().Msgf("Successfully sent friendship request message: %s", response)
	}

}

func (app *Application) updateFriendship(c *gin.Context) {
	friendship := struct {
		Status string `json:"status"`
	}{}
	err := c.BindJSON(&friendship)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	friendshipID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	friendshipFromDB, err := app.q.GetFriendshipById(c, friendshipID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No friendship found"})
		return
	}

	friendshipStatusId, err := app.q.GetFriendshipStatusId(app.ctx, friendship.Status)
	if err != nil {
		fmt.Print(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	updateSender, err := app.getUserFromContext(c)
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

	err = app.q.UpdateFriendship(app.ctx, db.UpdateFriendshipParams{
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

func (app *Application) deleteFriendship(c *gin.Context) {
	friendshipID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = app.q.DeleteFriendshipById(app.ctx, friendshipID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}
