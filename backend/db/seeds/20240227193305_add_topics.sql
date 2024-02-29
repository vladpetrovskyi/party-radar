-- +goose Up
-- +goose StatementBegin
INSERT INTO topic (name)
VALUES ('friendship-requests'),
       ('new-posts'),
       ('location-closed'),
       ('post-tags');
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE
FROM topic
WHERE name IN ('friendship-requests', 'new-posts', 'location-closed', 'post-tags');
-- +goose StatementEnd
