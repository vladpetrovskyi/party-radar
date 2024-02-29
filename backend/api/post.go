package api

import (
	"firebase.google.com/go/messaging"
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
	"strconv"
	"strings"
	"time"
)

type PostDTO struct {
	ID        int64     `json:"id"`
	Username  string    `json:"username"`
	PostType  string    `json:"post_type"`
	Location  *Location `json:"location"`
	ImageID   *int64    `json:"image_id"`
	Timestamp time.Time `json:"timestamp"`
	Views     *int64    `json:"views"`
	Capacity  *int64    `json:"capacity"`
}

func (app *Application) getPosts(c *gin.Context) {
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

	userFeedRows, err := app.q.GetUserPosts(c, db.GetUserPostsParams{
		UserID: userId,
		Offset: int32(offset),
		Limit:  int32(limit),
	})
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	userFeed := make([]PostDTO, 0)
	for _, post := range userFeedRows {
		mappedPost, err := app.mapDBUserPostToDTO(post)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		userFeed = append(userFeed, mappedPost)
	}

	c.JSON(http.StatusOK, userFeed)
}

func (app *Application) getFeed(c *gin.Context) {
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

	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No user found"})
		return
	}

	var rootLocationId *int64
	if id, err := strconv.ParseInt(c.Query("rootLocationId"), 10, 64); err != nil {
		rootLocationId = user.CurrentRootLocationID
	} else {
		rootLocationId = &id
	}

	username := "%" + strings.ToLower(c.Query("username")) + "%"

	userFeedRows, err := app.q.GetUserFeed(c, db.GetUserFeedParams{
		User2ID:        user.ID,
		Username:       &username,
		RootLocationID: rootLocationId,
		Offset:         int32(offset),
		Limit:          int32(limit),
	})
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	userFeed := make([]PostDTO, 0)
	for _, post := range userFeedRows {
		mappedPost, err := app.mapDBUserFeedPostToDTO(post)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		userFeed = append(userFeed, mappedPost)
	}

	c.JSON(http.StatusOK, userFeed)
}

func (app *Application) mapDBUserPostToDTO(entity db.GetUserPostsRow) (PostDTO, error) {
	location, err := app.getAndMapLocationFromDb(entity.LocationID)
	if err != nil {
		return PostDTO{}, err
	}

	location, err = app.buildLocationFromChild(location)
	if err != nil {
		return PostDTO{}, err
	}

	return PostDTO{
		ID:        entity.ID,
		Username:  *entity.Username,
		PostType:  entity.PostType,
		Location:  &location,
		Timestamp: entity.Timestamp,
		ImageID:   entity.ImageID,
	}, nil
}

func (app *Application) mapDBUserFeedPostToDTO(entity db.GetUserFeedRow) (PostDTO, error) {
	location, err := app.getAndMapLocationFromDb(entity.LocationID)
	if err != nil {
		return PostDTO{}, err
	}

	location, err = app.buildLocationFromChild(location)
	if err != nil {
		return PostDTO{}, err
	}

	return PostDTO{
		ID:        entity.ID,
		Username:  *entity.Username,
		PostType:  entity.PostType,
		Location:  &location,
		ImageID:   entity.ImageID,
		Timestamp: entity.Timestamp,
		Views:     entity.Views,
		Capacity:  entity.Capacity,
	}, nil
}

func (app *Application) getUserPostsCount(c *gin.Context) {
	username := strings.ToLower(c.Query("username"))
	if len(username) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Username cannot be empty"})
	}

	userPostsCount, err := app.q.GetUserPostsCount(c, &username)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"count": userPostsCount})
}

func (app *Application) deletePost(c *gin.Context) {
	postID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": err.Error()})
		return
	}

	err = app.q.DeletePost(c, postID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (app *Application) increaseViewsByOne(c *gin.Context) {
	postID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Cannot update post without ID"})
		return
	}

	err = app.q.IncreasePostViewsByOne(c, postID)
	if err != nil {
		msg := fmt.Sprintf("Could not update post views, post ID %d", postID)
		app.log.Debug().Ctx(c).Msg(msg)
		c.JSON(http.StatusBadRequest, gin.H{"msg": msg})
		return
	}

	c.Status(200)
}

func (app *Application) getPostViewsCount(c *gin.Context) {
	postID, err := app.readIDParam(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Cannot update post without ID"})
		return
	}

	viewsCount, err := app.q.GetPostViewsCount(c, postID)
	if err != nil {
		msg := fmt.Sprintf("Could not get post views count, post ID %d", postID)
		app.log.Debug().Ctx(c).Msg(msg)
		c.JSON(http.StatusBadRequest, gin.H{"msg": msg})
		return
	}

	c.JSON(http.StatusOK, gin.H{"count": *viewsCount})
}

func (app *Application) createPost(c *gin.Context) {
	post := struct {
		LocationID *int64 `json:"location_id"`
		PostType   string `json:"post_type"`
		Capacity   *int64 `json:"capacity"`
	}{}

	err := c.BindJSON(&post)
	if err != nil {
		app.log.Err(err).Ctx(c)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	postTypeId, err := app.q.GetPostTypeId(app.ctx, post.PostType)
	if err != nil {
		app.log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if post.LocationID == nil {
		if user.CurrentRootLocationID == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		post.LocationID = user.CurrentRootLocationID
	}

	tx, err := app.db.BeginTx(app.ctx, nil)
	if err != nil {
		app.log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer tx.Rollback()

	if err := app.q.WithTx(tx).CreatePost(app.ctx, db.CreatePostParams{
		UserID:     user.ID,
		LocationID: *post.LocationID,
		PostTypeID: postTypeId,
		Capacity:   post.Capacity,
	}); err != nil {
		app.log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err := app.q.WithTx(tx).UpdateUserLocation(app.ctx, db.UpdateUserLocationParams{
		ID:                user.ID,
		CurrentLocationID: post.LocationID,
	}); err != nil {
		app.log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if err = tx.Commit(); err != nil {
		app.log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	go app.sendNewPostNotification(user.ID, *user.Username)

	c.Status(http.StatusOK)
}

func (app *Application) sendNewPostNotification(userID int64, username string) {
	userFriendsFCMTokenIDs, err := app.q.GetUserFriendsFCMTokenIDsForTopic(app.ctx, db.GetUserFriendsFCMTokenIDsForTopicParams{
		ID:   userID,
		Name: "new-posts",
	})
	if err != nil {
		app.log.Err(err)
		return
	}

	messages := make([]*messaging.Message, 0)
	for _, token := range userFriendsFCMTokenIDs {

		message := messaging.Message{
			Notification: &messaging.Notification{
				Title: "New post",
				Body:  username + " has updated their location",
			},
			Data: map[string]string{
				"view": "posts",
			},
			Token: *token,
		}

		messages = append(messages, &message)
	}

	response, err := app.msg.SendAll(app.ctx, messages)
	if err != nil {
		app.log.Err(err)
		return
	}

	app.log.Debug().Msgf("Successfully sent %v / %v new post messages", response.SuccessCount, len(response.Responses))
}
