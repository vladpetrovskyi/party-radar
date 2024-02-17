package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func (app *application) healthcheckHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "available", "environment": app.cfg.env, "version": version})
}
