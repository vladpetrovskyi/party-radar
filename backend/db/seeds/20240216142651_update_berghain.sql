-- +goose Up
-- +goose StatementBegin
UPDATE dialog_settings
SET is_capacity_selectable = true
WHERE id IN (2, 4, 5, 6, 7);

UPDATE location as l
SET name  = t.name,
    emoji = t.emoji
FROM (VALUES (12, 'WC Bar', '🍸🚾'),
             (13, 'WC Chill Area', '🧘🚾'),
             (15, 'Dance Floor', '👯'),
             (17, 'Dance Floor', '👯'),
             (18, 'Bar (Pano)', '🍸'),
             (19, 'Chill Area (Pano)', '🧘'),
             (22, 'WC Chill Area', '🧘🚾'),
             (23, 'WC Bar', '🍸🚾'),
             (25, 'Dance Floor', '👯'),
             (26, 'FLINTA WC', '🚾'),
             (32, 'WC (Close)', '🤥👇'),
             (33, 'WC (Distant)', '🤥🚙')) as t(id, name, emoji)
WHERE l.id = t.id;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
UPDATE location as l
SET name  = t.name,
    emoji = t.emoji
FROM (VALUES (11, 'Bar (Main)', '🍸'),
             (12, 'WC Bar', '🍸🚽'),
             (13, 'WC Chill Area', '🧘🚽'),
             (15, 'Dance floor', '👯'),
             (17, 'Dance floor', '👯'),
             (18, 'Bar (Pano)', '🍸'),
             (19, 'Chill Area (Pano)', '🧘'),
             (22, 'WC Chill Area', '🧘🚽'),
             (23, 'WC Bar', '🍸🚽'),
             (25, 'Dancefloor', '👯'),
             (26, 'FLINTA WC', '🚾'),
             (32, 'WC (Close)', '🤥'),
             (33, 'WC (Distant)', '🤥')) as t(id, name, emoji)
WHERE l.id = t.id;

UPDATE dialog_settings
SET is_capacity_selectable = false
WHERE id IN (2, 4, 5, 6, 7);
-- +goose StatementEnd
