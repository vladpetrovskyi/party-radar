package common

import (
	"errors"
	"github.com/gin-gonic/gin"
	"party-time/db"
	"strconv"
)

func ReadIDParam(c *gin.Context) (id int64, err error) {
	id, err = strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		return 0, errors.New("incorrect ID")
	}
	return
}

func GetUserFromContext(ctl Controller, c *gin.Context) (db.GetUserByUIDRow, error) {
	uid := c.GetString("tokenUID")
	user, err := ctl.GetQ().GetUserByUID(c, &uid)
	if err != nil {
		ctl.GetLog().Error().AnErr("Could not get user by token UID", err)
		return db.GetUserByUIDRow{}, err
	}

	return user, nil
}
