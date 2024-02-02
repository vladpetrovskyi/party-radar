-- USER
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

-- name: UpdateUserImageId :exec
UPDATE "user"
SET image_id = $1
WHERE id = $2;

-- name: CreateUser :exec
INSERT INTO "user" (uid, email)
VALUES ($1, $2);

-- name: UpdateUser :exec
UPDATE "user"
SET username = $1,
    email    = $2
WHERE uid = $3;

-- name: UpdateUsername :exec
UPDATE "user"
SET username = $1
WHERE uid = $2;


-- IMAGE
-- name: GetImage :one
SELECT file_name, content
FROM image
WHERE id = $1;

-- name: CreateImage :one
INSERT INTO image (file_name, content)
VALUES ($1, $2)
RETURNING id;

-- name: UpdateImage :exec
UPDATE image
SET content   = $1,
    file_name = $2
WHERE id = $3;

-- name: DeleteImage :exec
DELETE
FROM image
WHERE id = $1;


-- LOCATION
-- name: GetLocation :one
SELECT l.id,
       l.name,
       l.emoji,
       l.enabled,
       l.column_index,
       l.parent_id,
       et.name  as element_type,
       oca.name AS on_click_action,
       ds.name  as dialog_name,
       ds.columns_number,
       ds.image_id
FROM location l
         LEFT JOIN element_type et on l.element_type_id = et.id
         LEFT JOIN on_click_action oca ON l.on_click_action_id = oca.id
         LEFT JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
WHERE l.id = $1;

-- name: GetLocationsByElementType :many
SELECT l.id, l.name, l.enabled
FROM location l
         LEFT JOIN element_type et ON l.element_type_id = et.id
WHERE parent_id IS NULL
  AND et.name = $1
ORDER BY l.name;

-- name: GetLocationChildren :many
SELECT l.id,
       l.name,
       l.emoji,
       l.enabled,
       l.column_index,
       et.name  as element_type,
       oca.name AS on_click_action,
       ds.name  as dialog_name,
       ds.columns_number,
       ds.image_id
FROM location l
         LEFT JOIN element_type et on l.element_type_id = et.id
         LEFT JOIN on_click_action oca ON l.on_click_action_id = oca.id
         LEFT JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
WHERE l.parent_id = $1;


-- FRIENDSHIP
-- name: GetFriendshipsCountByUser :one
SELECT COUNT(*)
FROM friendship f
WHERE (f.user_2_id = $1 OR f.user_1_id = $1)
  AND f.status_id = 2;

-- name: GetFriendshipsByUser :many
SELECT t.id::bigint       AS id,
       t.user_id::bigint  AS user_id,
       t.username::text   AS username,
       t.image_id::bigint AS image_id,
       l.name             AS location
FROM (SELECT f.id,
             CASE WHEN f.user_1_id != @userId::bigint then u1.id else u2.id END AS user_id,
             CASE
                 WHEN f.user_1_id != @userId::bigint then u1.username
                 else u2.username END                                           AS username,
             CASE
                 WHEN f.user_1_id != @userId::bigint then u1.image_id
                 else u2.image_id END                                           AS image_id,
             CASE
                 WHEN f.user_1_id != @userId::bigint then u1.current_root_location_id
                 else u2.current_root_location_id END                           AS current_root_location_id
      FROM friendship f
               LEFT JOIN "user" u1 ON f.user_1_id = u1.id
               LEFT JOIN "user" u2 ON f.user_2_id = u2.id
      WHERE (f.user_1_id = @userId::bigint
          OR f.user_2_id = @userId::bigint)
        AND f.status_id = 2) t
         LEFT JOIN location l ON l.id = t.current_root_location_id;

-- name: GetFriendshipRequestsByUser :many
SELECT f.id, u.id AS user_id, u.username, u.image_id, fs.name AS friendship_status, f.created_at, f.updated_at
FROM friendship f
         INNER JOIN friendship_status fs ON f.status_id = fs.id
         LEFT JOIN "user" u ON f.user_1_id = u.id
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
SELECT f.*, fs.name AS status
FROM friendship f
         INNER JOIN friendship_status fs on fs.id = f.status_id
WHERE (user_1_id = $1
    AND user_2_id = $2)
   OR (user_1_id = $2 AND user_2_id = $1);

-- name: GetFriendshipById :one
SELECT f.*, fs.name AS status
FROM friendship f
         INNER JOIN friendship_status fs ON f.status_id = fs.id
WHERE f.id = $1;


-- POST
-- name: GetUserFeed :many
SELECT p.id, p.user_id, u.username, pt.name AS post_type, p.location_id, u.image_id as image_id, p.timestamp
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
INSERT INTO post (user_id, location_id, post_type_id)
VALUES ($1, $2, $3);


-- POST TYPE
-- name: GetPostTypeId :one
SELECT id
FROM post_type
WHERE name = $1;


-- FRIENDSHIP STATUS
-- name: GetFriendshipStatusId :one
SELECT id
FROM friendship_status
WHERE name = $1;


-- DIALOG SETTINGS
-- name: UpdateDialogSettingsImage :exec
UPDATE dialog_settings
SET image_id = $1
WHERE id = $2;