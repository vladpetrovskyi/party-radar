-- name: CreateLocation :one
INSERT INTO location (name, enabled, element_type_id, on_click_action_id, column_index,
                      parent_id, root_location_id, row_index, owner_id, is_official, emoji)
VALUES ($1, $2, (SELECT et.id FROM element_type et WHERE et.name = sqlc.narg('element_type_name')),
        (SELECT oca.id FROM on_click_action oca WHERE oca.name = sqlc.narg('on_click_action_name')), $3, $4, $5, $6, $7,
        $8, $9)
RETURNING *;

-- name: GetLocation :one
SELECT l.id,
       l.name,
       l.emoji,
       l.enabled,
       l.column_index,
       l.row_index,
       l.parent_id,
       l.deleted_at,
       l.root_location_id,
       et.name       AS element_type,
       oca.name      AS on_click_action,
       ds.id         AS dialog_id,
       ds.name       AS dialog_name,
       ds.columns_number,
       i.id          AS image_id,
       ds.is_capacity_selectable,
       CASE
           WHEN lc.location_id IS NOT NULL
               THEN TRUE
           ELSE FALSE
           END::BOOL AS is_closeable,
       lc.closed_at,
       u.username    AS created_by,
       CASE
           WHEN l.is_official IS NOT NULL
               THEN TRUE
           ELSE FALSE
           END::BOOL AS is_official
FROM location l
         LEFT JOIN element_type et on l.element_type_id = et.id
         LEFT JOIN on_click_action oca ON l.on_click_action_id = oca.id
         LEFT JOIN dialog_settings ds ON l.id = ds.location_id
         LEFT JOIN location_closing lc ON l.id = lc.location_id
         LEFT JOIN "user" u ON l.owner_id = u.id
         LEFT JOIN image i ON i.dialog_settings_id = ds.id
WHERE l.id = $1
ORDER BY l.enabled DESC, l.name;

-- name: GetLocations :many
SELECT l.id,
       l.name,
       l.enabled,
       u.username                           AS created_by,
       coalesce(l.is_official, FALSE)::BOOL AS is_official
FROM location l
         LEFT JOIN element_type et ON l.element_type_id = et.id
         LEFT JOIN "user" u ON l.owner_id = u.id
WHERE parent_id IS NULL
  AND (et.name = @element_type_name OR @element_type_name IS NULL)
  AND (l.enabled = true OR (l.enabled = false AND u.id = sqlc.narg('user_id')))
  AND l.deleted_at IS NULL
ORDER BY l.name;

-- name: GetLocationChildren :many
SELECT l.id,
       l.name,
       l.emoji,
       l.enabled,
       l.column_index,
       l.row_index,
       l.parent_id,
       l.deleted_at,
       l.root_location_id,
       et.name       AS element_type,
       oca.name      AS on_click_action,
       ds.id         AS dialog_id,
       ds.name       AS dialog_name,
       ds.columns_number,
       i.id          AS image_id,
       ds.is_capacity_selectable,
       CASE
           WHEN lc.location_id IS NOT NULL
               THEN TRUE
           ELSE FALSE
           END::BOOL AS is_closeable,
       lc.closed_at
FROM location l
         LEFT JOIN element_type et on l.element_type_id = et.id
         LEFT JOIN on_click_action oca ON l.on_click_action_id = oca.id
         LEFT JOIN dialog_settings ds ON l.id = ds.location_id
         LEFT JOIN location_closing lc ON l.id = lc.location_id
         LEFT JOIN "user" u ON l.owner_id = u.id
         LEFT JOIN image i ON i.dialog_settings_id = ds.id
WHERE l.parent_id = $1
  AND l.deleted_at IS NULL
ORDER BY l.enabled DESC, l.name;

-- name: UpdateLocation :one
UPDATE location l
SET name               = $2,
    enabled            = $3,
    element_type_id    = (SELECT et.id FROM element_type et WHERE et.name = sqlc.narg('element_type_name')),
    on_click_action_id = (SELECT oca.id FROM on_click_action oca WHERE oca.name = sqlc.narg('on_click_action_name')),
    column_index       = $4,
    parent_id          = $5,
    root_location_id   = $6,
    row_index          = $7,
    emoji              = $8
WHERE l.id = $1
RETURNING *, (SELECT et.name FROM element_type et WHERE et.id = l.element_type_id) AS element_type, (SELECT oca.name
                                                                                                     FROM on_click_action oca
                                                                                                     WHERE oca.id = l.on_click_action_id) AS on_click_action;

-- name: SetLocationDeletedAt :exec
UPDATE location
SET deleted_at = NOW()
WHERE id = $1;

-- name: DeleteLocation :exec
DELETE
FROM location
WHERE id = $1;