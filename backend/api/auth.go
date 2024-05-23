package api

import (
	"firebase.google.com/go/auth"
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"strings"
)

func (app *Application) authorizeViaFirebase(obj, act string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token, verified := app.verifyToken(c)
		if !verified {
			app.respondWithError(http.StatusUnauthorized, "Unauthorized", c)
			return
		}

		ok, err := app.enforce(token.UID, obj, act)
		if err != nil {
			app.respondWithError(http.StatusInternalServerError, "error occurred when authorizing user", c)
			return
		}
		if !ok {
			app.respondWithError(http.StatusForbidden, "forbidden", c)
			return
		}

		c.Next()
	}
}

func (app *Application) authenticateViaFirebase() gin.HandlerFunc {
	return func(c *gin.Context) {
		app.verifyToken(c)
	}
}

func (app *Application) verifyToken(c *gin.Context) (token *auth.Token, verified bool) {
	authHeader := strings.SplitN(c.GetHeader("Authorization"), " ", 2)
	if len(authHeader) != 2 || authHeader[0] != "Bearer" {
		app.respondWithError(http.StatusUnauthorized, "Unauthorized", c)
		return
	}

	client, err := app.fb.Auth(app.ctx)
	if err != nil {
		app.respondWithError(http.StatusInternalServerError, fmt.Sprintf("error getting Auth client: %v", err), c)
		return
	}

	token, err = client.VerifyIDToken(app.ctx, authHeader[1])
	if err != nil {
		app.respondWithError(http.StatusUnauthorized, fmt.Sprintf("error verifying ID token: %v", err), c)
		return
	}

	c.Set("tokenUID", token.UID)
	return token, true
}

func (app *Application) enforce(sub string, obj string, act string) (bool, error) {
	ok, err := app.n4cer.Enforce(sub, obj, act)
	return ok, err
}
