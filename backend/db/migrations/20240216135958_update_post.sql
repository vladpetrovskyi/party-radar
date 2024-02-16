-- +goose Up
-- +goose StatementBegin
ALTER TABLE post ADD COLUMN views INT NULL;
ALTER TABLE post ADD COLUMN capacity INT NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE post DROP COLUMN capacity;
ALTER TABLE post DROP COLUMN views;
-- +goose StatementEnd
