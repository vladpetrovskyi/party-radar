-- name: GetUserByUsername :one
SELECT *
FROM "user"
WHERE username = $1;

-- name: GetUserByUID :one
SELECT *
FROM "user"
WHERE uid = $1;

-- name: UpdateUserRootLocation :exec
UPDATE "user"
SET current_root_location_id = $1
WHERE id = $2;

-- name: UpdateUserLocation :exec
UPDATE "user"
SET current_location_id = $1
WHERE id = $2;

-- name: CountUsersAtLocation :one
SELECT COUNT(*)
FROM "user" u
WHERE u.current_location_id = $2
  AND u.id IN (SELECT fs1.user_1_id AS user_id
               FROM friendship fs1
               WHERE fs1.user_2_id = $1
                 AND fs1.status_id = 2
               UNION
               SELECT fs2.user_2_id AS user_id
               FROM friendship fs2
               WHERE fs2.user_1_id = $1
                 AND fs2.status_id = 2);

-- name: CreateUser :exec
INSERT INTO "user" (uid, fcm_token)
VALUES ($1, $2);

-- name: UpdateUsername :exec
UPDATE "user"
SET username = $1
WHERE uid = $2;

-- name: UpdateFCMToken :exec
UPDATE "user"
SET fcm_token = $1
WHERE uid = $2;

-- name: DeleteUser :one
DELETE
FROM "user"
WHERE uid = $1
RETURNING *;

-- name: GetUsersByRootLocationID :many
SELECT * FROM "user" WHERE current_root_location_id = $1;
