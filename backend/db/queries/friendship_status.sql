-- name: GetFriendshipStatusId :one
SELECT id
FROM friendship_status
WHERE name = $1;