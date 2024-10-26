package user

import (
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"net/http"
	"party-time/api/common"
	"party-time/db"
)

type TopicController struct {
	q   *db.Queries
	log *zerolog.Logger
}

func NewTopicController(log *zerolog.Logger, q *db.Queries) *TopicController {
	return &TopicController{q: q, log: log}
}

func (ctl *TopicController) GetQ() *db.Queries {
	return ctl.q
}

func (ctl *TopicController) GetLog() *zerolog.Logger {
	return ctl.log
}

func (ctl *TopicController) SubscribeToTopic(c *gin.Context) {
	topic := struct {
		Name *string `json:"topic_name"`
	}{}

	if err := c.Bind(&topic); err != nil || topic.Name == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if user.FcmToken == nil {
		c.Status(http.StatusNoContent)
		return
	}

	if err := ctl.q.SubscribeToTopic(c, db.SubscribeToTopicParams{
		UserID: user.ID,
		Name:   *topic.Name,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (ctl *TopicController) UnsubscribeFromTopic(c *gin.Context) {
	topic := struct {
		Name *string `json:"topic_name"`
	}{}

	if err := c.Bind(&topic); err != nil || topic.Name == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if user.FcmToken == nil {
		c.Status(http.StatusNoContent)
		return
	}

	if err := ctl.q.UnsubscribeFromTopic(c, db.UnsubscribeFromTopicParams{
		UserID: user.ID,
		Name:   *topic.Name,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (ctl *TopicController) GetUserTopics(c *gin.Context) {
	user, err := common.GetUserFromContext(ctl, c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userTopics, err := ctl.q.GetTopicsByUserID(c, user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"topics": userTopics})
}
