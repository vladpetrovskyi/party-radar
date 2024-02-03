-- +goose Up
-- +goose StatementBegin
INSERT INTO dialog_settings (id, name, image_id, columns_number)
VALUES (1, 'Location selection', 1, 3), -- bh dance floor
       (2, 'Stall selection', 2, 3),    -- bh WC
       (3, 'Location selection', 3, 3), -- panorama bar dance floor
       (4, 'Stall selection', 4, 4),    -- panorama bar WC
       (5, 'Stall selection', 5, 4),    -- säule WC
       (6, 'Stall selection', 6, 4),    -- wardrobe close WC
       (7, 'Stall selection', 7, 4)     -- wardrobe distant WC
ON CONFLICT (id) DO UPDATE SET name           = excluded.name,
                               image_id       = excluded.image_id,
                               columns_number = excluded.columns_number;

INSERT INTO location (id, root_location_id, name, emoji, element_type_id, enabled, dialog_settings_id,
                      on_click_action_id, parent_id)
VALUES
    -- LEVEL 0
    (1, null, 'Berghain', null, 1, true, null, null, null),

    -- LEVEL 1
    (2, 1, 'Berghain', '🏢', 2, true, null, null, 1),
    (3, 1, 'Panorama Bar', '🪩', 2, true, null, null, 1),
    (4, 1, 'Säule', '📡', 2, true, null, null, 1),
    (5, 1, 'Wardrobe', '👜', 2, true, null, null, 1),
    (6, 1, 'Lab', '👊', 3, false, null, null, 1),
    (7, 1, 'Halle', '🧘', 3, false, null, null, 1),
    (8, 1, 'Garden', '🧑‍🌾', 3, false, null, null, 1),

    -- LEVEL 2:
    -- - Berghain
    (9, 1, 'Ice Bar', '🍨', 4, true, null, 1, 2),
    (10, 1, 'Darkroom', '😮‍💨', 4, true, null, 1, 2),
    (11, 1, 'Bar (Main)', '🍸', 4, true, null, 1, 2),
    (12, 1, 'WC Bar', '🍸🚽', 4, true, null, 1, 2),
    (13, 1, 'WC Chill Area', '🧘🚽', 4, true, null, 1, 2),
    (14, 1, 'Smoking Stairs', '🚬', 4, true, null, 1, 2),
    (15, 1, 'Dance floor', '👯', 4, true, 1, 2, 2),
    (16, 1, 'WC', '🤥', 4, true, 2, 2, 2),

    -- - Panorama Bar
    (17, 1, 'Dance floor', '👯', 4, true, 3, 2, 3),
    (18, 1, 'Bar (Pano)', '🍸', 4, true, null, 1, 3),
    (19, 1, 'Chill Area (Pano)', '🧘', 4, true, null, 1, 3),
    (20, 1, 'Balcony', '🪂', 4, true, null, 1, 3)
        ,
    (21, 1, 'WC', '🤥', 4, true, 4, 2, 3)
        ,
    (22, 1, 'WC Chill Area', '🧘🚽', 4, true, null, 1, 3)
        ,
    (23, 1, 'WC Bar', '🍸🚽', 4, true, null, 1, 3)
        ,
    (24, 1, 'Smoking Stairs', '🚬', 4, true, null, 1, 3)
        ,


    -- - Säule
    (25, 1, 'Dancefloor', '👯', 4, true, null, 1, 4)
        ,
    (26, 1, 'FLINTA WC', '👯', 4, true, null, 1, 4)
        ,
    (27, 1, 'Bar', '🍸', 4, true, null, 1, 4)
        ,
    (28, 1, 'Darkroom', '😮‍💨', 4, true, null, 1, 4)
        ,
    (29, 1, 'WC', '🤥', 4, true, 5, 2, 4)
        ,
    (30, 1, 'Chill Area', '🧘', 4, true, null, 1, 4)
        ,

    -- - Wardrobe
    (31, 1, 'Chill Area', '🧘', 4, true, null, 1, 5)
        ,
    (32, 1, 'WC (Close)', '🤥', 4, true, 6, 2, 5)
        ,
    (33, 1, 'WC (Distant)', '🤥', 4, true, 7, 2, 5)
ON CONFLICT(id)
    DO UPDATE SET root_location_id   = excluded.root_location_id,
                  name               = excluded.name,
                  emoji              = excluded.emoji,
                  element_type_id    = excluded.element_type_id,
                  enabled            = excluded.enabled,
                  dialog_settings_id = excluded.dialog_settings_id,
                  on_click_action_id = excluded.on_click_action_id,
                  parent_id          = excluded.parent_id;


INSERT INTO location (id, root_location_id, name, on_click_action_id, column_index, parent_id)
VALUES
    -- LEVEL 3:
    -- - Berghain
    -- - - Dance floor
    (34, 1, 'FL', 1, 0, 15),
    (35, 1, 'ML', 1, 0, 15),
    (36, 1, 'BL', 1, 0, 15),
    (37, 1, 'FM', 1, 1, 15),
    (38, 1, 'M', 1, 1, 15),
    (39, 1, 'BM', 1, 1, 15),
    (40, 1, 'FR', 1, 2, 15),
    (41, 1, 'MR', 1, 2, 15),
    (42, 1, 'BR', 1, 2, 15),

    -- - - WC
    (43, 1, 'LL3', 1, 0, 16),
    (44, 1, 'LL2', 1, 0, 16),
    (45, 1, 'LL1', 1, 0, 16),
    (46, 1, 'LR5', 1, 1, 16),
    (47, 1, 'LR4', 1, 1, 16),
    (48, 1, 'LR3', 1, 1, 16),
    (49, 1, 'LR2', 1, 1, 16),
    (50, 1, 'LR1', 1, 1, 16),
    (51, 1, 'RR5', 1, 2, 16),
    (52, 1, 'RR4', 1, 2, 16),
    (53, 1, 'RR3', 1, 2, 16),
    (54, 1, 'RR2', 1, 2, 16),
    (55, 1, 'RR1', 1, 2, 16),

    -- - Panorama Bar
    -- - - Dance floor
    (56, 1, 'FL', 1, 0, 17),
    (57, 1, 'BL', 1, 0, 17),
    (58, 1, 'FM', 1, 1, 17),
    (59, 1, 'BM', 1, 1, 17),
    (60, 1, 'FR', 1, 2, 17),
    (61, 1, 'BR', 1, 2, 17),

    -- - - WC
    (62, 1, 'BL1', 1, 0, 21),
    (63, 1, 'BL2', 1, 0, 21),
    (64, 1, 'FL1', 1, 1, 21),
    (65, 1, 'FL2', 1, 1, 21),
    (66, 1, 'FL3', 1, 1, 21),
    (67, 1, 'FL4', 1, 1, 21),
    (68, 1, 'FL5', 1, 1, 21),
    (69, 1, 'FR1', 1, 2, 21),
    (70, 1, 'FR2', 1, 2, 21),
    (71, 1, 'FR3', 1, 2, 21),
    (72, 1, 'FR4', 1, 2, 21),
    (73, 1, 'FR5', 1, 2, 21),
    (74, 1, 'BR1', 1, 3, 21),
    (75, 1, 'BR2', 1, 3, 21),
    (76, 1, 'BR3', 1, 3, 21),
    (77, 1, 'BR4', 1, 3, 21),
    (78, 1, 'BR5', 1, 3, 21),
    (79, 1, 'BR6', 1, 3, 21),

    -- - Säule
    -- - - WC
    (80, 1, 'L2', 1, 0, 29),
    (81, 1, 'L1', 1, 0, 29),
    (82, 1, 'R2', 1, 1, 29),
    (83, 1, 'R1', 1, 1, 29),

    -- - Wardrobe WC
    -- - - Close
    (84, 1, '1', 1, 0, 32),
    (85, 1, '2', 1, 0, 32),
    (86, 1, '3', 1, 1, 32),
    (87, 1, '4', 1, 1, 32),
    (88, 1, '5', 1, 2, 32),
    (89, 1, '6', 1, 2, 32),

    -- - - Distant
    (90, 1, 'L2', 1, 0, 33),
    (91, 1, 'L1', 1, 0, 33),
    (92, 1, 'R3', 1, 1, 33),
    (93, 1, 'R2', 1, 1, 33),
    (94, 1, 'R1', 1, 1, 33)
ON CONFLICT (id) DO UPDATE SET root_location_id   = excluded.root_location_id,
                               name               = excluded.name,
                               on_click_action_id = excluded.on_click_action_id,
                               column_index       = excluded.column_index,
                               parent_id          = excluded.parent_id,
                               emoji              = NULL,
                               element_type_id    = NULL,
                               enabled            = NULL,
                               dialog_settings_id = NULL;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE
FROM location
WHERE id > 0
  AND id < 95;

DELETE
FROM dialog_settings
WHERE id > 0
  AND id < 8;
-- +goose StatementEnd
