package api

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"party-time/db"
)

func (app *Application) subscribeToTopic(c *gin.Context) {
	topic := struct {
		Name *string `json:"topic_name"`
	}{}

	if err := c.Bind(&topic); err != nil || topic.Name == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if user.FcmToken == nil {
		c.Status(http.StatusNoContent)
		return
	}

	if err := app.q.SubscribeToTopic(c, db.SubscribeToTopicParams{
		UserID: user.ID,
		Name:   *topic.Name,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (app *Application) unsubscribeFromTopic(c *gin.Context) {
	topic := struct {
		Name *string `json:"topic_name"`
	}{}

	if err := c.Bind(&topic); err != nil || topic.Name == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if user.FcmToken == nil {
		c.Status(http.StatusNoContent)
		return
	}

	if err := app.q.UnsubscribeFromTopic(c, db.UnsubscribeFromTopicParams{
		UserID: user.ID,
		Name:   *topic.Name,
	}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusOK)
}

func (app *Application) getUserTopics(c *gin.Context) {
	user, err := app.getUserFromContext(c)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userTopics, err := app.q.GetTopicsByUserID(c, user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"topics": userTopics})
}
