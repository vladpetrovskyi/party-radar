package api

import (
	"party-time/api/dialogsettings"
	"party-time/api/friendship"
	"party-time/api/image"
	"party-time/api/location"
	"party-time/api/post"
	"party-time/api/user"
)

func (app *Application) newDialogSettingsController() *dialogsettings.Controller {
	return dialogsettings.NewController(app.log, app.q)
}

func (app *Application) newFriendshipController() *friendship.Controller {
	return friendship.NewController(app.q, app.log, app.msg)
}

func (app *Application) newImageController() *image.Controller {
	return image.NewController(app.log, app.db, app.q)
}

func (app *Application) newLocationController() *location.Controller {
	return location.NewController(app.log, app.q, app.db)
}

func (app *Application) newLocationClosingController() *location.ClosingController {
	return location.NewClosingController(app.log, app.q, app.msg)
}

func (app *Application) newPostController() *post.Controller {
	return post.NewController(app.q, app.log, app.db)
}

func (app *Application) newTopicController() *user.TopicController {
	return user.NewTopicController(app.log, app.q)
}

func (app *Application) newUserController() *user.Controller {
	return user.NewController(app.q, app.log, app.db, app.n4cer)
}
