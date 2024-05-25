# Party Radar App
![Header image](resources/cover.jpeg)

## Project purpose

This app is a project in production, thus available to download 
from the official stores (currently only AppStore supported). 
It is supposed to help people who go to parties at bigger clubs 
find each other.

## Available functions

* share current location (create a new post)
* get feed with friends' location posts
* add/delete friends
* add/delete posts in history
* create/update/delete account and account infos like:
  * username
  * profile picture

## Frontend

A Flutter application for Android and iOS devices.

## Backend

### Libraries used:
* ORM: [sqlc](https://sqlc.dev)
* Web Framework: [Gin](https://gin-gonic.com)
* Access control: [Casbin](https://casbin.org)
* Authentication: [Firebase](https://firebase.google.com)
* Logging: [zerolog](https://github.com/rs/zerolog)
* DB migration: [Goose](https://github.com/pressly/goose)

### Startup

To start the application locally:
1. run the [local docker-compose file](./backend/docker-compose.local.yaml)
2. run the [main_local.dart](./frontend/mobile/lib/main_local.dart) on the device of your choice

### Deployment

Backend can be deployed with GitHub Actions on dev and prod environments.

## Attributions / Credits
* [Person icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/person)
* [Female icons created by catkuro - Flaticon](https://www.flaticon.com/free-icons/female)
* [Male icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/male)
* [User icons created by kmg design - Flaticon](https://www.flaticon.com/free-icons/user)
* [Radar icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/radar)