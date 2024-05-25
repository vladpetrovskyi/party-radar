-- +goose Up
-- +goose StatementBegin
INSERT INTO location (id, root_location_id, name, emoji, element_type_id, enabled, dialog_settings_id,
                      on_click_action_id, parent_id)
VALUES
    (108, 1, 'Dance floor', '💃', 4, true, null, 1, 6),
    (109, 1, 'Toilets', '🌊', 4, true, null, 1, 6),
    (110, 1, 'Exploring', '🙂', 4, true, null, 1, 6)
ON CONFLICT(id)
    DO UPDATE SET root_location_id   = excluded.root_location_id,
                  name               = excluded.name,
                  emoji              = excluded.emoji,
                  element_type_id    = excluded.element_type_id,
                  enabled            = excluded.enabled,
                  dialog_settings_id = excluded.dialog_settings_id,
                  on_click_action_id = excluded.on_click_action_id,
                  parent_id          = excluded.parent_id;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE FROM location WHERE id IN (108, 109, 110);
-- +goose StatementEnd
