-- +goose Up
-- +goose StatementBegin
INSERT INTO location_closing (location_id)
SELECT l.id
FROM location l
         INNER JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
WHERE ds.is_capacity_selectable = true ON CONFLICT DO NOTHING;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE
FROM location_closing
WHERE location_id IN (SELECT l.id
             FROM location l
                      INNER JOIN dialog_settings ds ON l.dialog_settings_id = ds.id
             WHERE ds.is_capacity_selectable = true);
-- +goose StatementEnd
