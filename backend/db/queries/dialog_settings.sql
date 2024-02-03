-- name: UpdateDialogSettingsImage :exec
UPDATE dialog_settings
SET image_id = $1
WHERE id = $2;