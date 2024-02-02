package internal

import (
	"context"
	firebase "firebase.google.com/go"
	"firebase.google.com/go/auth"
	"fmt"
	"github.com/casbin/casbin/v2"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
	"net/http"
	"strings"
)

type AuthHandler struct {
	Ctx      context.Context
	Enforcer *casbin.Enforcer
	App      *firebase.App
}

func (h *AuthHandler) AuthorizeViaFirebase(obj, act string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := h.verifyToken(c)

		ok, err := h.enforce(token.UID, obj, act)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"msg": "error occurred when authorizing user"})
			return
		}
		if !ok {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"msg": "forbidden"})
			return
		}

		c.Next()
	}
}

func (h *AuthHandler) AuthenticateViaFirebase() gin.HandlerFunc {
	return func(c *gin.Context) {
		h.verifyToken(c)
	}
}

func (h *AuthHandler) verifyToken(c *gin.Context) (token *auth.Token) {
	authHeader := strings.SplitN(c.GetHeader("Authorization"), " ", 2)
	if len(authHeader) != 2 || authHeader[0] != "Bearer" {
		respondWithError(http.StatusUnauthorized, "Unauthorized", c)
		return
	}

	client, err := h.App.Auth(h.Ctx)
	if err != nil {
		respondWithError(http.StatusInternalServerError, fmt.Sprintf("error getting Auth client: %v", err), c)
		return
	}

	token, err = client.VerifyIDToken(h.Ctx, authHeader[1])
	if err != nil {
		respondWithError(http.StatusUnauthorized, fmt.Sprintf("error verifying ID token: %v", err), c)
		return
	}

	c.Set("tokenUID", token.UID)
	return
}

func respondWithError(code int, message string, c *gin.Context) {
	resp := map[string]string{"error": message}
	log.Debug().Msg(message)
	c.AbortWithStatusJSON(code, resp)
}

func (h *AuthHandler) enforce(sub string, obj string, act string) (bool, error) {
	ok, err := h.Enforcer.Enforce(sub, obj, act)
	return ok, err
}
