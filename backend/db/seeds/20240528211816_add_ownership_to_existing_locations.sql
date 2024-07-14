-- +goose Up
-- +goose StatementBegin
UPDATE location SET owner_id = 1 WHERE element_type_id = (SELECT id FROM element_type WHERE element_type.name = 'root');
UPDATE location SET is_official = TRUE WHERE element_type_id = (SELECT id FROM element_type WHERE element_type.name = 'root');
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
UPDATE location SET is_official = NULL WHERE is_official IS NOT NULL;
UPDATE location SET owner_id = NULL WHERE owner_id IS NOT NULL;
-- +goose StatementEnd
