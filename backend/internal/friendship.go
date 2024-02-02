package internal

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/db"
	"strconv"
)

type FriendshipHandler struct {
	Queries *db.Queries
	DB      *sql.DB
	Ctx     context.Context
}

func (h *FriendshipHandler) GetFriendships(c *gin.Context) {
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

	uid := c.GetString("tokenUID")
	user, err := h.Queries.GetUserByUID(h.Ctx, &uid)
	if err != nil {
		log.Debug().Ctx(c).Err(err).Msg("Could not get user by UID")
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if status == "requested" {
		friendshipRequests, err := h.Queries.GetFriendshipRequestsByUser(h.Ctx, db.GetFriendshipRequestsByUserParams{
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
		friends, err := h.Queries.GetFriendshipsByUser(h.Ctx, user.ID)
		if err != nil {
			log.Debug().Ctx(c).Err(err).Msg("Could not get friendships")
			c.JSON(http.StatusInternalServerError, err.Error())
			return
		}
		c.JSON(http.StatusOK, friends)
		return
	}

	log.Debug().Ctx(c).Msg("Unknown friendship status")
	c.JSON(http.StatusBadRequest, gin.H{"message": "Friendship status unrecognized"})
}

func (h *FriendshipHandler) GetFriendshipsCount(c *gin.Context) {
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

	user, err := h.Queries.GetUserByUID(h.Ctx, &uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var (
		friendshipsCount int64
	)
	if friendshipStatus == "requested" {
		friendshipsCount, err = h.Queries.GetFriendshipRequestsCountByUser(h.Ctx, user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	} else if friendshipStatus == "accepted" {
		friendshipsCount, err = h.Queries.GetFriendshipsCountByUser(h.Ctx, user.ID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, err.Error())
			return
		}
	}

	c.JSON(200, gin.H{"count": friendshipsCount})
}

func (h *FriendshipHandler) CreateFriendshipRequest(c *gin.Context) {
	uid := c.GetString("tokenUID")
	user, err := h.Queries.GetUserByUID(h.Ctx, &uid)
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

	userByUsername, err := h.Queries.GetUserByUsername(h.Ctx, requestUser.Username)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User not found"})
		return
	}

	if userByUsername.ID == user.ID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "friendship request cannot be sent to the person same as sender"})
		return
	}

	friendship, err := h.Queries.GetFriendshipByUserIds(c, db.GetFriendshipByUserIdsParams{
		User1ID: user.ID,
		User2ID: userByUsername.ID,
	})
	if err != nil {
		err = h.Queries.CreateFriendshipRequest(h.Ctx, db.CreateFriendshipRequestParams{
			User1ID: user.ID,
			User2ID: userByUsername.ID,
		})
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(200, nil)
		return
	}

	if friendship.Status == "accepted" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Can't send friendship request to a friend"})
		return
	}

	err = h.Queries.UpdateFriendship(h.Ctx, db.UpdateFriendshipParams{
		ID:       friendship.ID,
		User1ID:  user.ID,
		User2ID:  userByUsername.ID,
		StatusID: 1,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, nil)
}

func (h *FriendshipHandler) UpdateFriendship(c *gin.Context) {
	var (
		friendshipId int64
		err          error
	)

	friendship := struct {
		Status string `json:"status"`
	}{}
	err = c.BindJSON(&friendship)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	friendshipIdString := c.Param("id")
	if len(friendshipIdString) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Cannot update friendship without ID"})
		return

	}

	if friendshipId, err = strconv.ParseInt(c.Param("id"), 10, 64); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Friendship ID must be numeric"})
		return
	}

	friendshipFromDB, err := h.Queries.GetFriendshipById(c, friendshipId)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No friendship found"})
		return
	}

	friendshipStatusId, err := h.Queries.GetFriendshipStatusId(h.Ctx, friendship.Status)
	if err != nil {
		fmt.Print(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	uid := c.GetString("tokenUID")
	updateSender, err := h.Queries.GetUserByUID(h.Ctx, &uid)
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

	err = h.Queries.UpdateFriendship(h.Ctx, db.UpdateFriendshipParams{
		ID:       friendshipId,
		StatusID: friendshipStatusId,
		User1ID:  updateSender.ID,
		User2ID:  updateReceiverID,
	})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, nil)
}

func (h *FriendshipHandler) DeleteFriendship(c *gin.Context) {
	var (
		friendshipId int64
		err          error
	)
	if friendshipId, err = strconv.ParseInt(c.Param("id"), 10, 64); err != nil {
		fmt.Printf("[ERROR] parseLocationId: %v\n", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = h.Queries.DeleteFriendshipById(h.Ctx, friendshipId)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, nil)
}
