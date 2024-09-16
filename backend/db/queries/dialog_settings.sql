-- name: CreateDialogSettings :one
INSERT INTO dialog_settings (name, columns_number, is_capacity_selectable, location_id)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: UpdateDialogSettingsImage :exec
UPDATE image
SET dialog_settings_id = $1
WHERE id = $2;

-- name: UpdateDialogSettings :exec
UPDATE dialog_settings
SET name                   = $1,
    columns_number         = $2,
    is_capacity_selectable = $3
WHERE id = $4;

-- name: DeleteDialogSettings :exec
DELETE
FROM dialog_settings
WHERE id = $1;