-- name: GetPostTypeId :one
SELECT id
FROM post_type
WHERE name = $1;