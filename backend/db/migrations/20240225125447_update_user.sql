-- +goose Up
-- +goose StatementBegin
ALTER TABLE "user"
    ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255) NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE "user"
    DROP COLUMN fcm_token;
-- +goose StatementEnd
