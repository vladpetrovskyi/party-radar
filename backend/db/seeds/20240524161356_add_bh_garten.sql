-- +goose Up
-- +goose StatementBegin
INSERT INTO location (id, root_location_id, name, emoji, element_type_id, enabled, dialog_settings_id,
                      on_click_action_id, parent_id)
VALUES
    (102, 1, 'Balcony', '🪂', 4, true, null, 1, 8),
    (103, 1, 'Dance floor', '💃', 4, true, null, 1, 8),
    (104, 1, 'Jungle', '🌴', 4, true, null, 1, 8),
    (105, 1, 'Desert', '🏜', 4, true, null, 1, 8),
    (106, 1, 'DJ Container', '🚢', 4, true, null, 1, 8),
    (107, 1, 'Entrance Area', '🚪', 4, true, null, 1, 8)
ON CONFLICT(id)
    DO UPDATE SET root_location_id   = excluded.root_location_id,
                  name               = excluded.name,
                  emoji              = excluded.emoji,
                  element_type_id    = excluded.element_type_id,
                  enabled            = excluded.enabled,
                  dialog_settings_id = excluded.dialog_settings_id,
                  on_click_action_id = excluded.on_click_action_id,
                  parent_id          = excluded.parent_id;

UPDATE location SET enabled = true, element_type_id = 2 WHERE id = 8;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
UPDATE location SET enabled = false, element_type_id = 3 WHERE id = 8;

DELETE FROM location WHERE id IN (102, 103, 104, 105, 106, 107);
-- +goose StatementEnd
