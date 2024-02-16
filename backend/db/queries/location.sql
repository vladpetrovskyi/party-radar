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
       ds.image_id,
       ds.is_capacity_selectable
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
       ds.image_id,
       ds.is_capacity_selectable
FROM location l
         LEFT JOIN element_type et on l.element_type_id = et.id
         LEFT JOIN on_click_action oca ON l.on_click_action_id = oca.id
         LEFT JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
WHERE l.parent_id = $1;