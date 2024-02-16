-- +goose Up
-- +goose StatementBegin
ALTER TABLE dialog_settings ADD COLUMN is_capacity_selectable BOOL NOT NULL DEFAULT FALSE;-- +goose StatementEnd
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE dialog_settings DROP COLUMN is_capacity_selectable;
-- +goose StatementEnd
