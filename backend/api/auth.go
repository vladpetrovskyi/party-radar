package api

import (
	firebase "firebase.google.com/go"
	"firebase.google.com/go/auth"
	"fmt"
	"github.com/casbin/casbin/v2"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"net/http"
	"strings"
)

func (app *Application) authorizeViaFirebase(obj, act string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token, verified := verifyToken(app.log, app.fb, c)
		if !verified {
			respondWithError(app.log, http.StatusUnauthorized, "Unauthorized", c)
			return
		}

		ok, err := enforce(app.n4cer, token.UID, obj, act)
		if err != nil {
			respondWithError(app.log, http.StatusInternalServerError, "error occurred when authorizing user", c)
			return
		}
		if !ok {
			respondWithError(app.log, http.StatusForbidden, "forbidden", c)
			return
		}

		c.Next()
	}
}

func verifyToken(log *zerolog.Logger, fb *firebase.App, c *gin.Context) (token *auth.Token, verified bool) {
	authHeader := strings.SplitN(c.GetHeader("Authorization"), " ", 2)
	if len(authHeader) != 2 || authHeader[0] != "Bearer" {
		respondWithError(log, http.StatusUnauthorized, "Unauthorized", c)
		return
	}

	client, err := fb.Auth(c)
	if err != nil {
		respondWithError(log, http.StatusInternalServerError, fmt.Sprintf("error getting Auth client: %v", err), c)
		return
	}

	token, err = client.VerifyIDToken(c, authHeader[1])
	if err != nil {
		respondWithError(log, http.StatusUnauthorized, fmt.Sprintf("error verifying ID token: %v", err), c)
		return
	}

	c.Set("tokenUID", token.UID)
	return token, true
}

func enforce(n4cer *casbin.Enforcer, sub string, obj string, act string) (bool, error) {
	ok, err := n4cer.Enforce(sub, obj, act)
	return ok, err
}

func respondWithError(log *zerolog.Logger, code int, message string, c *gin.Context) {
	resp := gin.H{"error": message}
	log.Debug().Msg(message)
	c.AbortWithStatusJSON(code, resp)
}
