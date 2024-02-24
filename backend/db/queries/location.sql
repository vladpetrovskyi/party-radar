-- name: GetLocation :one
SELECT l.id,
       l.name,
       l.emoji,
       l.enabled,
       l.column_index,
       l.row_index,
       l.parent_id,
       l.deleted_at,
       et.name       AS element_type,
       oca.name      AS on_click_action,
       ds.name       AS dialog_name,
       ds.columns_number,
       ds.image_id,
       ds.is_capacity_selectable,
       CASE
           WHEN lc.location_id IS NOT NULL
               THEN TRUE
           ELSE FALSE
           END::BOOL AS is_closeable
FROM location l
         LEFT JOIN element_type et on l.element_type_id = et.id
         LEFT JOIN on_click_action oca ON l.on_click_action_id = oca.id
         LEFT JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
         LEFT JOIN location_closing lc ON l.id = lc.location_id
WHERE l.id = $1
ORDER BY l.enabled DESC, l.name;

-- name: GetLocationsByElementType :many
SELECT l.id, l.name, l.enabled
FROM location l
         LEFT JOIN element_type et ON l.element_type_id = et.id
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
       et.name       AS element_type,
       oca.name      AS on_click_action,
       ds.name       AS dialog_name,
       ds.columns_number,
       ds.image_id,
       ds.is_capacity_selectable,
       CASE
           WHEN lc.location_id IS NOT NULL
               THEN TRUE
           ELSE FALSE
           END::BOOL AS is_closeable
FROM location l
         LEFT JOIN element_type et on l.element_type_id = et.id
         LEFT JOIN on_click_action oca ON l.on_click_action_id = oca.id
         LEFT JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
         LEFT JOIN location_closing lc ON l.id = lc.location_id
WHERE l.parent_id = $1
  AND l.deleted_at IS NULL
ORDER BY l.enabled DESC, l.name;