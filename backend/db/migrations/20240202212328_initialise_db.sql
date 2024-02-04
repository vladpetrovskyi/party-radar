-- +goose Up
-- +goose StatementBegin
CREATE TABLE on_click_action
(
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE element_type
(
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE image
(
    id        SERIAL PRIMARY KEY,
    file_name TEXT  NOT NULL,
    content   BYTEA NOT NULL
);

CREATE TABLE dialog_settings
(
    id             SERIAL PRIMARY KEY,
    name           TEXT   NOT NULL,
    image_id       BIGINT NULL,
    columns_number INT    NULL,
    CONSTRAINT fk_dialog_image FOREIGN KEY (image_id) REFERENCES image (id)
);

CREATE TABLE location
(
    id                 SERIAL PRIMARY KEY,
    name               TEXT   NOT NULL,
    emoji              TEXT   NULL,
    enabled            BOOL   NOT NULL DEFAULT TRUE,
    element_type_id    BIGINT NULL,
    dialog_settings_id BIGINT NULL,
    on_click_action_id BIGINT NULL,
    column_index       INT    NULL,
    parent_id          BIGINT NULL,
    root_location_id   BIGINT NULL,
    CONSTRAINT fk_location_element_type FOREIGN KEY (element_type_id) REFERENCES element_type (id),
    CONSTRAINT fk_location_dialog_settings FOREIGN KEY (dialog_settings_id) REFERENCES dialog_settings (id),
    CONSTRAINT fk_location_on_click_action FOREIGN KEY (on_click_action_id) REFERENCES on_click_action (id),
    CONSTRAINT fk_location_parent FOREIGN KEY (parent_id) REFERENCES location (id),
    CONSTRAINT fk_location_root FOREIGN KEY (root_location_id) REFERENCES location (id)
);

CREATE TABLE "user"
(
    id                       SERIAL PRIMARY KEY,
    uid                      TEXT   NULL UNIQUE,
    username                 TEXT   NULL UNIQUE,
    image_id                 BIGINT NULL,
    current_location_id      BIGINT NULL,
    current_root_location_id BIGINT NULL,
    CONSTRAINT fk_user_image FOREIGN KEY (image_id) REFERENCES image (id),
    CONSTRAINT fk_user_current_location FOREIGN KEY (current_location_id) REFERENCES location (id),
    CONSTRAINT fk_user_current_root_location FOREIGN KEY (current_root_location_id) REFERENCES location (id)
);

CREATE TABLE friendship_status
(
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE friendship
(
    id         SERIAL PRIMARY KEY,
    user_1_id  BIGINT NOT NULL,
    user_2_id  BIGINT NOT NULL,
    status_id  BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP   NULL,
    CONSTRAINT fk_friendship_status FOREIGN KEY (status_id) REFERENCES friendship_status (id),
    CONSTRAINT fk_user_1_friendship FOREIGN KEY (user_1_id) REFERENCES "user" (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_2_friendship FOREIGN KEY (user_2_id) REFERENCES "user" (id) ON DELETE CASCADE,
    CONSTRAINT uk_friendship_user_1_user_2 UNIQUE (user_1_id, user_2_id)
);

CREATE TABLE post_type
(
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE post
(
    id           SERIAL PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    location_id  BIGINT NOT NULL,
    post_type_id BIGINT NOT NULL,
    timestamp    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_post_user FOREIGN KEY (user_id) REFERENCES "user" (id) ON DELETE CASCADE,
    CONSTRAINT fk_post_location FOREIGN KEY (location_id) REFERENCES location (id),
    CONSTRAINT fk_post_type FOREIGN KEY (post_type_id) REFERENCES post_type (id)
);

CREATE OR REPLACE FUNCTION update_changetimestamp_column()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.updated_at = now();
RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_ab_changetimestamp
    BEFORE UPDATE
    ON friendship
    FOR EACH ROW
    EXECUTE PROCEDURE
        update_changetimestamp_column();
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TRIGGER update_ab_changetimestamp ON friendship;
DROP FUNCTION update_changetimestamp_column();
DROP TABLE post;
DROP TABLE post_type;
DROP TABLE friendship;
DROP TABLE friendship_status;
DROP TABLE "user";
DROP TABLE location;
DROP TABLE dialog_settings;
DROP TABLE image;
DROP TABLE element_type;
DROP TABLE on_click_action;
-- +goose StatementEnd
