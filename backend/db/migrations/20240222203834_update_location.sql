-- +goose Up
-- +goose StatementBegin
BEGIN;

CREATE TABLE IF NOT EXISTS location_closing (
    location_id BIGINT NOT NULL PRIMARY KEY,
    closed_at TIMESTAMP NULL,
    CONSTRAINT fk_location FOREIGN KEY (location_id) REFERENCES location (id)
);

ALTER TABLE location ADD COLUMN IF NOT EXISTS row_index INT NULL;
ALTER TABLE location ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL;

COMMIT;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
BEGIN;

ALTER TABLE location DROP COLUMN IF EXISTS row_index;
DROP TABLE IF EXISTS location_closing;

COMMIT;
-- +goose StatementEnd
