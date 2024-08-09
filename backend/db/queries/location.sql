-- name: CreateLocation :one
INSERT INTO location (name, enabled, element_type_id, dialog_settings_id, on_click_action_id, column_index,
                      parent_id, root_location_id, row_index, owner_id, is_official)
VALUES ($1, $2, (SELECT et.id FROM element_type et WHERE et.name = @element_type_name::text), $3,
        (SELECT oca.id FROM on_click_action oca WHERE oca.name = sqlc.narg('on_click_action_name')), $4, $5, $6, $7, $8,
        $9)
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
       ds.image_id,
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
         LEFT JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
         LEFT JOIN location_closing lc ON l.id = lc.location_id
         LEFT JOIN "user" u ON l.owner_id = u.id
WHERE l.id = $1
ORDER BY l.enabled DESC, l.name;

-- name: GetLocationsByElementType :many
SELECT l.id,
       l.name,
       l.enabled,
       u.username    AS created_by,
       CASE
           WHEN l.is_official IS NOT NULL
               THEN TRUE
           ELSE FALSE
           END::BOOL AS is_official
FROM location l
         LEFT JOIN element_type et ON l.element_type_id = et.id
         LEFT JOIN "user" u ON l.owner_id = u.id
WHERE parent_id IS NULL
  AND et.name = $1
ORDER BY l.enabled DESC, l.name;

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
       ds.image_id,
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
         LEFT JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
         LEFT JOIN location_closing lc ON l.id = lc.location_id
         LEFT JOIN "user" u ON l.owner_id = u.id
WHERE l.parent_id = $1
  AND l.deleted_at IS NULL
ORDER BY l.enabled DESC, l.name;