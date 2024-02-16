-- name: GetUserFeed :many
SELECT p.id, p.user_id, u.username, pt.name AS post_type, p.location_id, u.image_id as image_id, p.timestamp, p.views, p.capacity
FROM post p
         INNER JOIN post_type pt ON p.post_type_id = pt.id
         INNER JOIN location l ON p.location_id = l.id
         LEFT JOIN "user" u ON p.user_id = u.id
WHERE ((l.root_location_id = $1 AND p.post_type_id = 2) OR (l.id = $1 AND p.post_type_id IN (1, 3)))
  AND p.timestamp >= now() - INTERVAL '3 DAYS'
  AND p.user_id IN (SELECT fs1.user_1_id AS user_id
                    FROM friendship fs1
                    WHERE fs1.user_2_id = $2
                      AND fs1.status_id = 2
                    UNION
                    SELECT fs2.user_2_id AS user_id
                    FROM friendship fs2
                    WHERE fs2.user_1_id = $2
                      AND fs2.status_id = 2)
  AND u.username LIKE $3
ORDER BY p.timestamp DESC
LIMIT $4 OFFSET $5;

-- name: GetUserPosts :many
SELECT p.id, p.user_id, u.username, pt.name AS post_type, p.location_id, u.image_id as image_id, p.timestamp
FROM post p
         INNER JOIN post_type pt ON p.post_type_id = pt.id
         LEFT JOIN "user" u ON p.user_id = u.id
WHERE p.user_id = $1
ORDER BY p.timestamp DESC
LIMIT $2 OFFSET $3;

-- name: GetUserPostsCount :one
SELECT COUNT(*)
FROM post p
         LEFT JOIN "user" u ON p.user_id = u.id
WHERE u.username = $1;

-- name: CreatePost :exec
INSERT INTO post (user_id, location_id, post_type_id, capacity)
VALUES ($1, $2, $3, $4);

-- name: DeletePost :exec
DELETE
FROM post
WHERE id = $1;

-- name: IncreasePostViewsByOne :exec
UPDATE post SET views = COALESCE(views, 0) + 1 WHERE id = $1;