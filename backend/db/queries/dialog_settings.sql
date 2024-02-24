-- name: UpdateDialogSettingsImage :exec
UPDATE dialog_settings
SET image_id = $1
WHERE id = $2;

-- name: GetDialogSettingsImageID :one
SELECT image_id FROM dialog_settings WHERE id = $1;