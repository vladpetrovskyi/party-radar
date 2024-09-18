package api

import (
	"errors"
	"github.com/gin-gonic/gin"
	"party-time/db"
	"strconv"
)

func (app *Application) readIDParam(c *gin.Context) (id int64, err error) {
	id, err = strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		app.log.Error().AnErr("Incorrect ID", err)
		return 0, errors.New("incorrect ID")
	}
	return
}

func (app *Application) getUserFromContext(c *gin.Context) (db.GetUserByUIDRow, error) {
	uid := c.GetString("tokenUID")
	user, err := app.q.GetUserByUID(app.ctx, &uid)
	if err != nil {
		app.log.Error().AnErr("Could not get user by token UID", err)
		return db.GetUserByUIDRow{}, err
	}

	return user, nil
}

func (app *Application) respondWithError(code int, message string, c *gin.Context) {
	resp := gin.H{"error": message}
	app.log.Debug().Msg(message)
	c.AbortWithStatusJSON(code, resp)
}
