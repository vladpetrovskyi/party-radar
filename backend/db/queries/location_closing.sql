-- name: GetLocationClosingTimeByLocationID :one
SELECT closed_at FROM location_closing WHERE location_id = $1;

-- name: CloseLocationByID :exec
UPDATE location_closing SET closed_at = now() WHERE location_id = $1;

-- name: OpenLocationByID :exec
UPDATE location_closing SET closed_at = NULL WHERE location_id = $1;