-- +goose Up
-- +goose StatementBegin
INSERT INTO location (id, root_location_id, name, emoji, element_type_id, enabled, dialog_settings_id,
                      on_click_action_id, parent_id)
VALUES
    -- LEVEL 0
    (95, null, 'Club OST', null, 1, false, null, null, null),
    (96, null, 'RSO', null, 1, false, null, null, null),
    (97, null, 'OXI', null, 1, false, null, null, null),
    (98, null, 'KitKat', null, 1, false, null, null, null);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE
FROM location
WHERE id > 94
  AND id < 99;
-- +goose StatementEnd
