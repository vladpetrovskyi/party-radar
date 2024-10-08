-- name: GetFriendshipsCountByUser :one
SELECT COUNT(*)
FROM friendship f
WHERE (f.user_2_id = $1 OR f.user_1_id = $1)
  AND f.status_id = 2;

-- name: GetFriendshipsByUser :many
SELECT t.id       AS id,
       t.user_id  AS user_id,
       t.username AS username,
       t.image_id AS image_id,
       l.name     AS location
FROM (SELECT f.id,
             CASE WHEN f.user_1_id != @userId::bigint then u1.id else u2.id END AS user_id,
             CASE
                 WHEN f.user_1_id != @userId::bigint then u1.username
                 else u2.username END                                           AS username,
             CASE
                 WHEN f.user_1_id != @userId::bigint then i1.id
                 else i2.id END                                                 AS image_id,
             CASE
                 WHEN f.user_1_id != @userId::bigint then u1.current_root_location_id
                 else u2.current_root_location_id END                           AS current_root_location_id
      FROM friendship f
               LEFT JOIN "user" u1 ON f.user_1_id = u1.id
               LEFT JOIN "user" u2 ON f.user_2_id = u2.id
               LEFT JOIN image i1 ON u1.id = i1.user_id
               LEFT JOIN image i2 ON u2.id = i2.user_id
      WHERE (f.user_1_id = @userId::bigint
          OR f.user_2_id = @userId::bigint)
        AND f.status_id = 2) t
         LEFT JOIN location l ON l.id = t.current_root_location_id
LIMIT $1 OFFSET $2;

-- name: GetFriendshipRequestsByUser :many
SELECT f.id, u.id AS user_id, u.username, i.id AS image_id, fs.name AS friendship_status, f.created_at, f.updated_at
FROM friendship f
         INNER JOIN friendship_status fs ON f.status_id = fs.id
         LEFT JOIN "user" u ON f.user_1_id = u.id
         LEFT JOIN image i ON i.user_id = u.id
WHERE status_id = 1
  AND user_2_id = $1
LIMIT $2 OFFSET $3;

-- name: GetFriendshipRequestsCountByUser :one
SELECT COUNT(*)
from friendship
WHERE status_id = 1
  AND user_2_id = $1;

-- name: CreateFriendshipRequest :exec
INSERT INTO friendship (user_1_id, user_2_id, status_id)
VALUES ($1, $2, 1)
ON CONFLICT ON CONSTRAINT uk_friendship_user_1_user_2 DO UPDATE SET status_id = 1;

-- name: UpdateFriendship :exec
UPDATE friendship
SET status_id = $1,
    user_1_id = $2,
    user_2_id = $3
WHERE id = $4;

-- name: DeleteFriendshipById :exec
DELETE
FROM friendship
WHERE id = $1;

-- name: GetFriendshipByUserIds :one
SELECT f.id, fs.name AS status
FROM friendship f
         INNER JOIN friendship_status fs on fs.id = f.status_id
         LEFT JOIN public."user" u ON f.user_1_id = u.id AND f.user_2_id = u.id
WHERE (user_1_id = $1
    AND user_2_id = $2)
   OR (user_1_id = $2 AND user_2_id = $1);

-- name: GetFriendshipById :one
SELECT f.*, fs.name AS status
FROM friendship f
         INNER JOIN friendship_status fs ON f.status_id = fs.id
WHERE f.id = $1;

-- name: GetUserFriendsByRootLocationIDAndTopicName :many
SELECT u.*
FROM "user" u
         LEFT JOIN friendship f ON f.user_1_id = u.id OR f.user_2_id = u.id
         LEFT JOIN user_topic ut ON u.id = ut.user_id
         LEFT JOIN topic t ON ut.topic_id = t.id
WHERE u.id != $1
  AND (f.user_1_id = $1 OR f.user_2_id = $1)
  AND u.fcm_token IS NOT NULL
  AND u.current_root_location_id = $3
  AND t.name = $2;