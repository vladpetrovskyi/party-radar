-- +goose Up
-- +goose StatementBegin
INSERT INTO user_topic (user_id, topic_id)
SELECT u.id, t.id
FROM "user" u
         CROSS JOIN topic t
WHERE t.name != 'post-tags'
  AND u.username IS NOT NULL
ON CONFLICT DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE
FROM user_topic
WHERE user_id IN (SELECT id FROM "user" WHERE username IS NOT NULL);
-- +goose StatementEnd
