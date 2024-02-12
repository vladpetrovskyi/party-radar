package internal

import (
	"context"
	"database/sql"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"net/http"
	"party-time/db"
	"strconv"
	"strings"
	"time"
)

type PostHandler struct {
	Queries         *db.Queries
	DB              *sql.DB
	Ctx             context.Context
	LocationHandler *LocationHandler
}

type PostDTO struct {
	ID        int64     `json:"id"`
	Username  string    `json:"username"`
	PostType  string    `json:"post_type"`
	Location  *Location `json:"location"`
	ImageID   *int64    `json:"image_id"`
	Timestamp time.Time `json:"timestamp"`
}

func (h *PostHandler) GetPosts(c *gin.Context) {
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

	userFeedRows, err := h.Queries.GetUserPosts(c, db.GetUserPostsParams{
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
		mappedPost, err := h.mapDBUserPostToDTO(post)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		userFeed = append(userFeed, mappedPost)
	}

	c.JSON(http.StatusOK, userFeed)
}

func (h *PostHandler) GetFeed(c *gin.Context) {
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
	username := "%" + strings.ToLower(c.Query("username")) + "%"

	uid := c.GetString("tokenUID")
	user, err := h.Queries.GetUserByUID(c, &uid)
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

	userFeedRows, err := h.Queries.GetUserFeed(c, db.GetUserFeedParams{
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
		mappedPost, err := h.mapDBUserFeedPostToDTO(post)
		if err != nil {
			c.JSON(500, gin.H{"error": err.Error()})
			return
		}
		userFeed = append(userFeed, mappedPost)
	}

	c.JSON(http.StatusOK, userFeed)
}

func (h *PostHandler) mapDBUserPostToDTO(entity db.GetUserPostsRow) (PostDTO, error) {
	location, err := h.LocationHandler.getAndMapLocationFromDb(entity.LocationID)
	if err != nil {
		return PostDTO{}, err
	}

	location, err = h.LocationHandler.buildLocationFromChild(location)
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

func (h *PostHandler) mapDBUserFeedPostToDTO(entity db.GetUserFeedRow) (PostDTO, error) {
	location, err := h.LocationHandler.getAndMapLocationFromDb(entity.LocationID)
	if err != nil {
		return PostDTO{}, err
	}

	location, err = h.LocationHandler.buildLocationFromChild(location)
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
	}, nil
}

func (h *PostHandler) GetUserPostsCount(c *gin.Context) {
	username := strings.ToLower(c.Query("username"))
	if len(username) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"message": "Username cannot be empty"})
	}

	userPostsCount, err := h.Queries.GetUserPostsCount(c, &username)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"count": userPostsCount})
}

func (h *PostHandler) DeletePost(c *gin.Context) {
	postStringId := c.Param("id")
	if len(postStringId) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Cannot delete post without ID"})
		return
	}

	var (
		postId int64
		err    error
	)
	if postId, err = strconv.ParseInt(c.Param("id"), 10, 64); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"msg": "Friendship ID must be numeric"})
		return
	}

	err = h.Queries.DeletePost(c, postId)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (h *PostHandler) CreatePost(c *gin.Context) {
	post := struct {
		LocationID *int64 `json:"location_id"`
		PostType   string `json:"post_type"`
	}{}

	err := c.BindJSON(&post)
	if err != nil {
		log.Err(err).Ctx(c)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	uid := c.GetString("tokenUID")
	user, err := h.Queries.GetUserByUID(h.Ctx, &uid)
	if err != nil {
		log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	postTypeId, err := h.Queries.GetPostTypeId(h.Ctx, post.PostType)
	if err != nil {
		log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if post.LocationID == nil {
		post.LocationID = user.CurrentRootLocationID
	}

	if post.LocationID == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.Queries.CreatePost(h.Ctx, db.CreatePostParams{
		UserID:     user.ID,
		LocationID: *post.LocationID,
		PostTypeID: postTypeId,
	})
	if err != nil {
		log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	err = h.Queries.UpdateUserLocation(h.Ctx, db.UpdateUserLocationParams{
		ID:                user.ID,
		CurrentLocationID: post.LocationID,
	})
	if err != nil {
		log.Err(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(200)
}
