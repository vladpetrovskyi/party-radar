-- +goose Up
-- +goose StatementBegin
ALTER TABLE location ADD COLUMN IF NOT EXISTS owner_id BIGINT NULL;
ALTER TABLE location ADD CONSTRAINT fk_location_user FOREIGN KEY (owner_id) REFERENCES "user" (id);

ALTER TABLE location ADD COLUMN IF NOT EXISTS is_official BOOLEAN NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE location DROP CONSTRAINT IF EXISTS fk_location_user;
ALTER TABLE location DROP COLUMN IF EXISTS owner_id;

ALTER TABLE location DROP COLUMN IF EXISTS is_official;
-- +goose StatementEnd
