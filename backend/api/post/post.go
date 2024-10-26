package post

import (
	"database/sql"
	"firebase.google.com/go/messaging"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/api/common"
	"party-time/api/location"
	"party-time/api/user"
	"party-time/db"
	"strconv"
	"strings"
	"time"
)

type Controller struct {
	q   *db.Queries
	log *zerolog.Logger
	db  *sql.DB
	msg *messaging.Client
}

type DTO struct {
	ID        int64              `json:"id"`
	Username  string             `json:"username"`
	PostType  string             `json:"post_type"`
	Location  *location.Location `json:"location"`
	ImageID   *int64             `json:"image_id"`
	Timestamp time.Time          `json:"timestamp"`
	Views     *int64             `json:"views"`
	Capacity  *int64             `json:"capacity"`
}

type incomingPostDTO struct {
	LocationID *int64 `json:"location_id"`
	Type       string `json:"post_type"`
	Capacity   *int64 `json:"capacity"`
}

func NewController(q *db.Queries, log *zerolog.Logger, db *sql.DB) *Controller {
	return &Controller{q: q, log: log, db: db}
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

func (ctl *Controller) GetDB() *sql.DB {
	return ctl.db
}

func (ctl *Controller) GetPosts(c *gin.Context) {
	offset, err := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	limit, err := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	userIdString := c.Query("userId")
	userId, err := strconv.ParseInt(userIdString, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User ID must be numeric"})
		return
	}

	userFeedRows, err := ctl.q.GetUserPosts(c, db.GetUserPostsParams{
		UserID: userId,
		Offset: int32(offset),
		Limit:  int32(limit),
	})
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	userFeed := make([]DTO, 0)
	for _, post := range userFeedRows {
		mappedPost, err := mapDBUserPostToDTO(ctl.q, c, post)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		userFeed = append(userFeed, mappedPost)
	}

	c.JSON(http.StatusOK, userFeed)
}

func (ctl *Controller) GetFeed(c *gin.Context) {
	offset, err := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Offset value must be numeric"})
		return
	}
	limit, err := strconv.Atoi(c.DefaultQuery("limit", "10"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Limit value must be numeric"})
		return
	}

	u, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No u found"})
		return
	}

	var rootLocationId *int64
	if id, err := strconv.ParseInt(c.Query("rootLocationId"), 10, 64); err != nil {
		rootLocationId = u.CurrentRootLocationID
	} else {
		rootLocationId = &id
	}

	username := "%" + strings.ToLower(c.Query("username")) + "%"

	userFeedRows, err := ctl.q.GetUserFeed(c, db.GetUserFeedParams{
		User2ID:        u.ID,
		Username:       &username,
		RootLocationID: rootLocationId,
		Offset:         int32(offset),
		Limit:          int32(limit),
	})
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	userFeed := make([]DTO, 0)
	for _, post := range userFeedRows {
		mappedPost, err := mapDBUserFeedPostToDTO(ctl.q, c, post)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		userFeed = append(userFeed, mappedPost)
	}

	c.JSON(http.StatusOK, userFeed)
}

func (ctl *Controller) GetUserPostsCount(c *gin.Context) {
	username := strings.ToLower(c.Query("username"))
	if len(username) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Username cannot be empty"})
	}

	userPostsCount, err := ctl.q.GetUserPostsCount(c, &username)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"count": userPostsCount})
}

func (ctl *Controller) DeletePost(c *gin.Context) {
	postID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = ctl.q.DeletePost(c, postID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (ctl *Controller) IncreaseViewsByOne(c *gin.Context) {
	postID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Cannot update post without ID"})
		return
	}

	err = ctl.q.IncreasePostViewsByOne(c, postID)
	if err != nil {
		msg := fmt.Sprintf("Could not update post views, post ID %d", postID)
		ctl.log.Debug().Ctx(c).Msg(msg)
		c.JSON(http.StatusBadRequest, gin.H{"msg": msg})
		return
	}

	c.Status(200)
}

func (ctl *Controller) GetPostViewsCount(c *gin.Context) {
	postID, err := common.ReadIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Cannot update post without ID"})
		return
	}

	viewsCount, err := ctl.q.GetPostViewsCount(c, postID)
	if err != nil {
		msg := fmt.Sprintf("Could not get post views count, post ID %d", postID)
		ctl.log.Debug().Ctx(c).Msg(msg)
		c.JSON(http.StatusBadRequest, gin.H{"msg": msg})
		return
	}

	c.JSON(http.StatusOK, gin.H{"count": *viewsCount})
}

func (ctl *Controller) CreatePost(c *gin.Context) {
	var post incomingPostDTO

	err := c.BindJSON(&post)
	if err != nil {
		ctl.log.Err(err).Msg("Failed to bind JSON while creating a post")
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	u, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if post.LocationID == nil {
		if u.CurrentRootLocationID == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		post.LocationID = u.CurrentRootLocationID
	}

	err = user.CreatePostForUser(ctl, c, u.ID, *post.LocationID, post.Type, post.Capacity)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var currentRootLocationID *int64
	if u.CurrentRootLocationID != nil {
		currentRootLocationID = u.CurrentRootLocationID
	} else {
		currentRootLocationID = post.LocationID
	}

	go sendNewPostNotification(ctl, c, u.ID, *u.Username, currentRootLocationID, post)

	c.Status(http.StatusOK)
}

func mapDBUserPostToDTO(q *db.Queries, c *gin.Context, entity db.GetUserPostsRow) (DTO, error) {
	loc, err := location.GetAndMapLocationFromDb(q, c, entity.LocationID)
	if err != nil {
		return DTO{}, err
	}

	loc, err = location.BuildLocationFromChild(q, c, loc)
	if err != nil {
		return DTO{}, err
	}

	return DTO{
		ID:        entity.ID,
		Username:  *entity.Username,
		PostType:  entity.PostType,
		Location:  &loc,
		Timestamp: entity.Timestamp,
		ImageID:   entity.ImageID,
	}, nil
}

func mapDBUserFeedPostToDTO(q *db.Queries, c *gin.Context, entity db.GetUserFeedRow) (DTO, error) {
	loc, err := location.GetAndMapLocationFromDb(q, c, entity.LocationID)
	if err != nil {
		return DTO{}, err
	}

	loc, err = location.BuildLocationFromChild(q, c, loc)
	if err != nil {
		return DTO{}, err
	}

	return DTO{
		ID:        entity.ID,
		Username:  *entity.Username,
		PostType:  entity.PostType,
		Location:  &loc,
		ImageID:   entity.ImageID,
		Timestamp: entity.Timestamp,
		Views:     entity.Views,
		Capacity:  entity.Capacity,
	}, nil
}

func sendNewPostNotification(ctl common.MessagingController, c *gin.Context, userID int64, username string, currentRootLocationID *int64, post incomingPostDTO) {
	userFriends, err := ctl.GetQ().GetUserFriendsByRootLocationIDAndTopicName(c, db.GetUserFriendsByRootLocationIDAndTopicNameParams{
		ID:                    userID,
		Name:                  "new-posts",
		CurrentRootLocationID: currentRootLocationID,
	})
	if err != nil {
		log.Err(err).Msg("Could not GetUserFriendsByRootLocationIDAndTopicName while trying to send new post notifications")
		return
	}

	var body string
	if post.Type == "start" {
		body = "Arrived at the club!"
	} else if post.Type == "end" {
		body = "Left the club"
	} else {
		loc, err := location.GetAndMapLocationFromDb(ctl.GetQ(), c, *post.LocationID)
		if err != nil {
			log.Err(err).Msg("Could not get and map loc from db while trying to send new post notifications")
			return
		}

		parentLocation, err := location.BuildLocationFromChild(ctl.GetQ(), c, loc)
		if err != nil {
			log.Err(err).Msg("Could not build loc from child while trying to send new post notifications")
			return
		}

		if parentLocation.ParentID == nil {
			parentLocation = parentLocation.Children[0]
		}

		if len(parentLocation.Children) == 0 {
			body = parentLocation.Name
		} else {
			emoji := ""
			if parentLocation.Children[0].Emoji != nil {
				emoji = " " + *parentLocation.Children[0].Emoji
			}

			body = parentLocation.Name + ": " + parentLocation.Children[0].Name + emoji
		}
	}

	messages := make([]*messaging.Message, 0)
	for _, userFriend := range userFriends {
		if userFriend.FcmToken != nil {
			message := messaging.Message{
				Notification: &messaging.Notification{
					Title: username,
					Body:  body,
				},
				Data: map[string]string{
					"view": "posts",
				},
				Token: *userFriend.FcmToken,
			}
			messages = append(messages, &message)
		}
	}

	if len(messages) == 0 {
		return
	}

	response, err := ctl.GetMsg().SendAll(c, messages)
	if err != nil {
		log.Err(err).Msg("Could not send new post notification messages")
		return
	}

	log.Debug().Msgf("Successfully sent %v / %v new post messages", response.SuccessCount, len(response.Responses))
}
