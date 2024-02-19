package api

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func (app *Application) healthcheckHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "available", "environment": app.c.Server.Environment})
}
