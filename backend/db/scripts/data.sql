INSERT INTO element_type (name)
VALUES ('root'),          -- 1
       ('expansionTile'), -- 2
       ('listTile'),      -- 3
       ('card'); -- 4

INSERT INTO on_click_action (name)
VALUES ('select'), -- 1
       ('openDialog'); -- 2

INSERT INTO dialog_settings (name, image_id, columns_number)
VALUES ('Location selection', null, 3), -- bh dance floor
       ('Stall selection', null, 3),    -- bh WC
       ('Location selection', null, 3), -- panorama bar dance floor
       ('Stall selection', null, 4),    -- panorama bar WC
       ('Stall selection', null, 4),    -- säule WC
       ('Stall selection', null, 4),    -- garderobe close WC
       ('Stall selection', null, 4); -- garderobe distant WC

INSERT INTO location (root_location_id, name, emoji, element_type_id, enabled, dialog_settings_id, on_click_action_id,
                      parent_id)
VALUES
    -- LEVEL 0
    (null, 'Berghain', null, 1, true, null, null, null), -- 1

    -- LEVEL 1
    (1, 'Berghain', '🏢', 2, true, null, null, 1),        -- 2
    (1, 'Panorama Bar', '🪩', 2, true, null, null, 1),    -- 3
    (1, 'Säule', '📡', 2, true, null, null, 1),           -- 4
    (1, 'Wardrobe', '👜', 2, true, null, null, 1),        -- 5
    (1, 'Lab', '👊', 3, false, null, null, 1),            -- 6
    (1, 'Halle', '🧘', 3, false, null, null, 1),          -- 7
    (1, 'Garden', '🧑‍🌾', 3, false, null, null, 1),       -- 8

    -- LEVEL 2:
    -- - Berghain
    (1, 'Ice Bar', '🍨', 4, true, null, 1, 2),            -- 9
    (1, 'Darkroom', '😮‍💨', 4, true, null, 1, 2),         -- 10
    (1, 'Bar (Main)', '🍸', 4, true, null, 1, 2),         -- 11
    (1, 'WC Bar', '🍸🚽', 4, true, null, 1, 2),            -- 12
    (1, 'WC Chill Area', '🧘🚽', 4, true, null, 1, 2),     -- 13
    (1, 'Smoking Stairs', '🚬', 4, true, null, 1, 2),     -- 14
    (1, 'Dance floor', '👯', 4, true, 1, 2, 2),           -- 15
    (1, 'WC', '🤥', 4, true, 2, 2, 2),                    -- 16

    -- - Panorama Bar
    (1, 'Dance floor', '👯', 4, true, 3, 2, 3),           -- 17
    (1, 'Bar (Pano)', '🍸', 4, true, null, 1, 3),         -- 18
    (1, 'Chill Area (Pano)', '🧘', 4, true, null, 1, 3),  -- 19
    (1, 'Balcony', '🪂', 4, true, null, 1, 3),            -- 20
    (1, 'WC', '🤥', 4, true, 4, 2, 3),                    -- 21
    (1, 'WC Chill Area', '🧘🚽', 4, true, null, 1, 3),     -- 22
    (1, 'WC Bar', '🍸🚽', 4, true, null, 1, 3),            -- 23
    (1, 'Smoking Stairs', '🚬', 4, true, null, 1, 3),     -- 24


    -- - Säule
    (1, 'Dancefloor', '👯', 4, true, null, 1, 4),         -- 25
    (1, 'FLINTA WC', '👯', 4, true, null, 1, 4),          -- 26
    (1, 'Bar', '🍸', 4, true, null, 1, 4),                -- 27
    (1, 'Darkroom', '😮‍💨', 4, true, null, 1, 4),         -- 28
    (1, 'WC', '🤥', 4, true, 5, 2, 4),                    -- 29
    (1, 'Chill Area', '🧘', 4, true, null, 1, 4),         -- 30

    -- - Wardrobe
    (1, 'Chill Area', '🧘', 4, true, null, 1, 5),         -- 31
    (1, 'WC (Close)', '🤥', 4, true, 6, 2, 5),            -- 32
    (1, 'WC (Distant)', '🤥', 4, true, 7, 2, 5); -- 33

INSERT INTO location (root_location_id, name, on_click_action_id, column_index, parent_id)
VALUES
    -- LEVEL 3:
    -- - Berghain
    -- - - Dance floor
    (1, 'FL', 1, 0, 15),
    (1, 'ML', 1, 0, 15),
    (1, 'BL', 1, 0, 15),
    (1, 'FM', 1, 1, 15),
    (1, 'M', 1, 1, 15),
    (1, 'BM', 1, 1, 15),
    (1, 'FR', 1, 2, 15),
    (1, 'MR', 1, 2, 15),
    (1, 'BR', 1, 2, 15),

    -- - - WC
    (1, 'LL3', 1, 0, 16),
    (1, 'LL2', 1, 0, 16),
    (1, 'LL1', 1, 0, 16),
    (1, 'LR5', 1, 1, 16),
    (1, 'LR4', 1, 1, 16),
    (1, 'LR3', 1, 1, 16),
    (1, 'LR2', 1, 1, 16),
    (1, 'LR1', 1, 1, 16),
    (1, 'RR5', 1, 2, 16),
    (1, 'RR4', 1, 2, 16),
    (1, 'RR3', 1, 2, 16),
    (1, 'RR2', 1, 2, 16),
    (1, 'RR1', 1, 2, 16),

    -- - Panorama Bar
    -- - - Dance floor
    (1, 'FL', 1, 0, 17),
    (1, 'BL', 1, 0, 17),
    (1, 'FM', 1, 1, 17),
    (1, 'BM', 1, 1, 17),
    (1, 'FR', 1, 2, 17),
    (1, 'BR', 1, 2, 17),

    -- - - WC
    (1, 'BL1', 1, 0, 21),
    (1, 'BL2', 1, 0, 21),
    (1, 'FL1', 1, 1, 21),
    (1, 'FL2', 1, 1, 21),
    (1, 'FL3', 1, 1, 21),
    (1, 'FL4', 1, 1, 21),
    (1, 'FL5', 1, 1, 21),
    (1, 'FR1', 1, 2, 21),
    (1, 'FR2', 1, 2, 21),
    (1, 'FR3', 1, 2, 21),
    (1, 'FR4', 1, 2, 21),
    (1, 'FR5', 1, 2, 21),
    (1, 'BR1', 1, 3, 21),
    (1, 'BR2', 1, 3, 21),
    (1, 'BR3', 1, 3, 21),
    (1, 'BR4', 1, 3, 21),
    (1, 'BR5', 1, 3, 21),
    (1, 'BR6', 1, 3, 21),

    -- - Säule
    -- - - WC
    (1, 'L2', 1, 0, 29),
    (1, 'L1', 1, 0, 29),
    (1, 'R2', 1, 1, 29),
    (1, 'R1', 1, 1, 29),

    -- - Garderobe WC
    -- - - Close
    (1, '1', 1, 0, 32),
    (1, '2', 1, 0, 32),
    (1, '3', 1, 1, 32),
    (1, '4', 1, 1, 32),
    (1, '5', 1, 2, 32),
    (1, '6', 1, 2, 32),

    -- - - Distant
    (1, 'L2', 1, 0, 33),
    (1, 'L1', 1, 0, 33),
    (1, 'R3', 1, 1, 33),
    (1, 'R2', 1, 1, 33),
    (1, 'R1', 1, 1, 33);


INSERT INTO friendship_status (name)
VALUES ('requested'),
       ('accepted'),
       ('rejected');

INSERT INTO post_type (name)
VALUES ('start'),
       ('ongoing'),
       ('end');