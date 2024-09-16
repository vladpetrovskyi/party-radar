-- +goose Up
-- +goose StatementBegin
BEGIN;

ALTER TABLE dialog_settings
    ADD COLUMN location_id BIGINT,
    ADD CONSTRAINT fk_location FOREIGN KEY (location_id) REFERENCES location (id) ON DELETE CASCADE;
UPDATE dialog_settings ds
SET location_id = l.id
FROM location l
WHERE ds.id = l.dialog_settings_id;
ALTER TABLE location
    DROP CONSTRAINT fk_location_dialog_settings,
    DROP COLUMN dialog_settings_id;
ALTER TABLE location
    DROP CONSTRAINT fk_location_parent;
ALTER TABLE location
    ADD CONSTRAINT fk_location_parent FOREIGN KEY (parent_id) REFERENCES location (id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE image
    ADD COLUMN dialog_settings_id BIGINT,
    ADD CONSTRAINT fk_dialog_settings FOREIGN KEY (dialog_settings_id) REFERENCES dialog_settings (id) ON DELETE CASCADE;
UPDATE image i
SET dialog_settings_id = ds.id
FROM dialog_settings ds
WHERE ds.image_id = i.id;
ALTER TABLE dialog_settings
    DROP CONSTRAINT fk_dialog_image,
    DROP COLUMN image_id;

ALTER TABLE image
    ADD COLUMN user_id BIGINT,
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES "user" (id) ON DELETE CASCADE;
UPDATE image i
SET user_id = u.id
FROM "user" u
WHERE u.image_id = i.id;
ALTER TABLE "user"
    DROP CONSTRAINT fk_user_image,
    DROP COLUMN image_id;

ALTER TABLE location_closing
    DROP CONSTRAINT fk_location,
    ADD CONSTRAINT fk_location FOREIGN KEY (location_id) REFERENCES location (id) ON DELETE CASCADE;

ALTER TABLE user_topic
    DROP CONSTRAINT fk_user_topic_id,
    DROP CONSTRAINT fk_user_id,
    ADD CONSTRAINT fk_user_topic_id FOREIGN KEY (topic_id) REFERENCES topic (id) ON UPDATE CASCADE ON DELETE CASCADE,
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES "user" (id) ON DELETE CASCADE;

COMMIT;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
BEGIN;

ALTER TABLE location
    ADD COLUMN dialog_settings_id BIGINT,
    ADD CONSTRAINT fk_location_dialog_settings FOREIGN KEY (dialog_settings_id) REFERENCES dialog_settings (id);
UPDATE location l
SET dialog_settings_id = ds.id
FROM dialog_settings ds
WHERE ds.location_id = l.id;
ALTER TABLE dialog_settings
    DROP CONSTRAINT fk_location,
    DROP COLUMN location_id;

ALTER TABLE dialog_settings
    ADD COLUMN image_id BIGINT,
    ADD CONSTRAINT fk_dialog_image FOREIGN KEY (image_id) REFERENCES image (id);
UPDATE dialog_settings ds
SET image_id = i.id
FROM image i
WHERE ds.id = i.dialog_settings_id;
ALTER TABLE image
    DROP CONSTRAINT fk_dialog_settings,
    DROP COLUMN dialog_settings_id;

ALTER TABLE "user"
    ADD COLUMN image_id BIGINT,
    ADD CONSTRAINT fk_user_image FOREIGN KEY (image_id) REFERENCES image (id);
UPDATE "user" u
SET image_id = i.id
FROM image i
WHERE u.id = i.user_id;
ALTER TABLE image
    DROP CONSTRAINT fk_user,
    DROP COLUMN user_id;

ALTER TABLE location_closing
    DROP CONSTRAINT fk_location,
    ADD CONSTRAINT fk_location FOREIGN KEY (location_id) REFERENCES location (id);

ALTER TABLE user_topic
    DROP CONSTRAINT fk_user_topic_id,
    DROP CONSTRAINT fk_user_id,
    ADD CONSTRAINT fk_user_topic_id FOREIGN KEY (topic_id) REFERENCES topic (id),
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES "user" (id);

COMMIT;
-- +goose StatementEnd
