-- +goose Up
-- +goose StatementBegin
BEGIN;

CREATE TABLE IF NOT EXISTS topic (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS user_topic (
    user_id BIGINT NOT NULL,
    topic_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, topic_id),
    CONSTRAINT fk_user_topic_id FOREIGN KEY (topic_id) REFERENCES topic (id),
    CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES "user" (id)
);

COMMIT;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
BEGIN;
DROP TABLE IF EXISTS user_topic;
DROP TABLE IF EXISTS topic;
COMMIT;
-- +goose StatementEnd
