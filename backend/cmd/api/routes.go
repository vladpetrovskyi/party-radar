package main

import (
	"github.com/gin-contrib/logger"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"net/http"
)

func (app *application) routes() http.Handler {
	app.log.Info().Msg("Setting up API routes...")

	router := gin.New()
	router.Use(logger.SetLogger(logger.WithLogger(func(context *gin.Context, z zerolog.Logger) zerolog.Logger {
		return *app.log
	})))

	v1 := router.Group("/api/v1")
	v1.GET("/healthcheck", app.healthcheckHandler)

	imageGroup := v1.Group("/image")
	imageGroup.HEAD("/:id", app.authorizeViaFirebase("data", "read"), app.checkImageExists)
	imageGroup.GET("/:id", app.authorizeViaFirebase("data", "read"), app.getImage)
	imageGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createImage)
	imageGroup.PUT("/:id", app.authorizeViaFirebase("data", "write"), app.updateImage)

	userGroup := v1.Group("/user")
	userGroup.POST("/registration", app.register)
	userGroup.HEAD("/:username", app.authorizeViaFirebase("data", "read"), app.getUserByUsername)
	userGroup.GET("/:username", app.authorizeViaFirebase("data", "read"), app.getUserByUsername)
	userGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getUserByUID)
	userGroup.DELETE("", app.authorizeViaFirebase("data", "write"), app.deleteUser)
	userGroup.PUT("/username", app.authorizeViaFirebase("data", "write"), app.updateUsername)
	userGroup.PUT("/root-location/:id", app.authorizeViaFirebase("data", "write"), app.updateUserRootLocation)
	userGroup.DELETE("/location", app.authorizeViaFirebase("data", "write"), app.deleteUserLocation)

	locationGroup := v1.Group("/location")
	locationGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getLocations)
	locationGroup.GET("/:id", app.authorizeViaFirebase("data", "read"), app.getLocation)
	locationGroup.GET("/:id/user/count", app.authorizeViaFirebase("data", "read"), app.getLocationUserCount)

	postGroup := v1.Group("/post")
	postGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getPosts)
	postGroup.GET("/feed", app.authorizeViaFirebase("data", "read"), app.getFeed)
	postGroup.GET("/count", app.authorizeViaFirebase("data", "read"), app.getUserPostsCount)
	postGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createPost)
	postGroup.PUT("/:id/view", app.authorizeViaFirebase("data", "write"), app.increaseViewsByOne)
	postGroup.DELETE("/:id", app.authorizeViaFirebase("data", "write"), app.deletePost)

	friendshipGroup := v1.Group("/friendship")
	friendshipGroup.GET("", app.authorizeViaFirebase("data", "read"), app.getFriendships)
	friendshipGroup.GET("/count", app.authorizeViaFirebase("data", "read"), app.getFriendshipsCount)
	friendshipGroup.POST("", app.authorizeViaFirebase("data", "write"), app.createFriendshipRequest)
	friendshipGroup.PUT("/:id", app.authorizeViaFirebase("data", "write"), app.updateFriendship)
	friendshipGroup.DELETE("/:id", app.authorizeViaFirebase("data", "write"), app.deleteFriendship)

	app.log.Info().Msg("API routes setup finished")

	return router
}
