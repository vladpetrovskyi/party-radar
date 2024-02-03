-- name: GetImage :one
SELECT file_name, content
FROM image
WHERE id = $1;

-- name: CreateImage :one
INSERT INTO image (file_name, content)
VALUES ($1, $2)
RETURNING id;

-- name: UpsertImage :exec
INSERT INTO image (id, file_name, content)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO UPDATE SET file_name = excluded.file_name,
                               content   = excluded.content;

-- name: UpdateImage :exec
UPDATE image
SET content   = $1,
    file_name = $2
WHERE id = $3;

-- name: DeleteImage :exec
DELETE
FROM image
WHERE id = $1;