-- +goose Up
-- +goose StatementBegin
BEGIN;

INSERT INTO dialog_settings (id, name, image_id, columns_number, is_capacity_selectable)
VALUES (8, 'Stall selection', null, 5, true),
       (9, 'Stall selection', null, 2, true)
ON CONFLICT (id) DO UPDATE SET name                   = excluded.name,
                               image_id               = excluded.image_id,
                               columns_number         = excluded.columns_number,
                               is_capacity_selectable = excluded.is_capacity_selectable;

INSERT INTO location (id, root_location_id, name, emoji, element_type_id, enabled, dialog_settings_id,
                      on_click_action_id, parent_id)
VALUES (99, 1, 'WC (Right)', '🤥➡️', 4, true, 8, 2, 2),
       (101, 1, 'WC (Left)', '🤥⬅️', 4, true, 9, 2, 2)
ON CONFLICT (id) DO UPDATE SET name               = excluded.name,
                               emoji              = excluded.emoji,
                               enabled            = excluded.enabled,
                               element_type_id    = excluded.element_type_id,
                               on_click_action_id = excluded.on_click_action_id,
                               parent_id          = excluded.parent_id,
                               dialog_settings_id = excluded.dialog_settings_id,
                               root_location_id   = excluded.root_location_id;

UPDATE location
SET deleted_at = now()
WHERE id = 16;

UPDATE location
SET name = 'WC (Far)'
WHERE id = 33;

INSERT INTO location (id, name, emoji, enabled, element_type_id, on_click_action_id, parent_id, root_location_id)
VALUES (100, 'Chill Swing', '🎢', true, 4, 1, 2, 1)
ON CONFLICT (id) DO UPDATE SET name               = excluded.name,
                               emoji              = excluded.emoji,
                               enabled            = excluded.enabled,
                               element_type_id    = excluded.element_type_id,
                               on_click_action_id = excluded.on_click_action_id,
                               parent_id          = excluded.parent_id,
                               root_location_id   = excluded.root_location_id;

UPDATE location AS l
SET name         = t.name,
    parent_id    = t.parent_id,
    column_index = t.column_index,
    row_index    = t.row_index
FROM (VALUES -- LEVEL 3:
             -- - Berghain
             -- - - Dance floor
             (34, 'FL', 0, 15, 0),
             (35, 'ML', 0, 15, 1),
             (36, 'BL', 0, 15, 2),
             (37, 'FM', 1, 15, 0),
             (38, 'M', 1, 15, 1),
             (39, 'BM', 1, 15, 2),
             (40, 'FR', 2, 15, 0),
             (41, 'MR', 2, 15, 1),
             (42, 'BR', 2, 15, 2),

             -- - - WC
             (43, 'L3', 0, 101, 0),
             (44, 'L2', 0, 101, 1),
             (45, 'L1', 0, 101, 2),
             (46, 'R5', 1, 101, 0),
             (47, 'R4', 1, 101, 1),
             (48, 'R3', 1, 101, 2),
             (49, 'R2', 1, 101, 3),
             (50, 'R1', 1, 101, 4),
             (51, '5', 4, 99, 0),
             (52, '4', 3, 99, 0),
             (53, '3', 2, 99, 0),
             (54, '2', 1, 99, 0),
             (55, '1', 0, 99, 0),

             -- - Panorama Bar
             -- - - Dance floor
             (56, 'FL', 0, 17, 0),
             (57, 'BL', 0, 17, 1),
             (58, 'FM', 1, 17, 0),
             (59, 'BM', 1, 17, 1),
             (60, 'FR', 2, 17, 0),
             (61, 'BR', 2, 17, 1),

             -- - - WC
             (62, 'BL1', 0, 21, 0),
             (63, 'BL2', 0, 21, 1),
             (64, 'FL1', 1, 21, 0),
             (65, 'FL2', 1, 21, 1),
             (66, 'FL3', 1, 21, 2),
             (67, 'FL4', 1, 21, 3),
             (69, 'FR1', 2, 21, 0),
             (70, 'FR2', 2, 21, 1),
             (71, 'FR3', 2, 21, 2),
             (72, 'FR4', 2, 21, 3),
             (74, 'BR1', 3, 21, 0),
             (75, 'BR2', 3, 21, 1),
             (76, 'BR3', 3, 21, 2),
             (77, 'BR4', 3, 21, 3),
             (78, 'BR5', 3, 21, 4),
             (79, 'BR6', 3, 21, 5),

             -- - Säule
             -- - - WC
             (80, 'L2', 0, 29, 0),
             (81, 'L1', 0, 29, 1),
             (82, 'R2', 1, 29, 0),
             (83, 'R1', 1, 29, 1),

             -- - Wardrobe WC
             -- - - Close
             (84, '1', 0, 32, 0),
             (85, '2', 1, 32, 0),
             (86, '3', 2, 32, 0),
             (87, '4', 3, 32, 0),
             (88, '5', 4, 32, 0),
             (89, '6', 5, 32, 0),

             -- - - Distant
             (90, 'L2', 0, 33, 0),
             (91, 'L1', 0, 33, 1),
             (92, 'R3', 1, 33, 0),
             (93, 'R2', 1, 33, 1),
             (94, 'R1', 1, 33, 2)) as t(id, name, column_index, parent_id, row_index)
WHERE l.id = t.id;

COMMIT;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
BEGIN;

DELETE
FROM dialog_settings
WHERE id IN (8, 9);

UPDATE dialog_settings
SET columns_number = 3
WHERE id = 2;

DELETE
FROM location
WHERE id IN (99, 101);

UPDATE location
SET deleted_at = NULL
WHERE id = 16;

UPDATE location
SET name = 'WC (Distant)'
WHERE id = 33;

DELETE
FROM location
WHERE name = 'Chill Swing'
  AND parent_id = 2;

UPDATE location AS l
SET name         = t.name,
    parent_id    = t.parent_id,
    column_index = t.column_index,
    row_index    = t.row_index
FROM (VALUES -- LEVEL 3:
             -- - Berghain
             -- - - Dance floor
             (34, 'FL', 0, 15, null),
             (35, 'ML', 0, 15, null),
             (36, 'BL', 0, 15, null),
             (37, 'FM', 1, 15, null),
             (38, 'M', 1, 15, null),
             (39, 'BM', 1, 15, null),
             (40, 'FR', 2, 15, null),
             (41, 'MR', 2, 15, null),
             (42, 'BR', 2, 15, null),

             -- - - WC
             (43, 'LL3', 0, 16, null),
             (44, 'LL2', 0, 16, null),
             (45, 'LL1', 0, 16, null),
             (46, 'LR5', 1, 16, null),
             (47, 'LR4', 1, 16, null),
             (48, 'LR3', 1, 16, null),
             (49, 'LR2', 1, 16, null),
             (50, 'LR1', 1, 16, null),
             (51, 'RR5', 2, 16, null),
             (52, 'RR4', 2, 16, null),
             (53, 'RR3', 2, 16, null),
             (54, 'RR2', 2, 16, null),
             (55, 'RR1', 2, 16, null),

             -- - Panorama Bar
             -- - - Dance floor
             (56, 'FL', 0, 17, null),
             (57, 'BL', 0, 17, null),
             (58, 'FM', 1, 17, null),
             (59, 'BM', 1, 17, null),
             (60, 'FR', 2, 17, null),
             (61, 'BR', 2, 17, null),

             -- - - WC
             (62, 'BL1', 0, 21, null),
             (63, 'BL2', 0, 21, null),
             (64, 'FL1', 1, 21, null),
             (65, 'FL2', 1, 21, null),
             (66, 'FL3', 1, 21, null),
             (67, 'FL4', 1, 21, null),
             (69, 'FR1', 2, 21, null),
             (70, 'FR2', 2, 21, null),
             (71, 'FR3', 2, 21, null),
             (72, 'FR4', 2, 21, null),
             (74, 'BR1', 3, 21, null),
             (75, 'BR2', 3, 21, null),
             (76, 'BR3', 3, 21, null),
             (77, 'BR4', 3, 21, null),
             (78, 'BR5', 3, 21, null),
             (79, 'BR6', 3, 21, null),

             -- - Säule
             -- - - WC
             (80, 'L2', 0, 29, null),
             (81, 'L1', 0, 29, null),
             (82, 'R2', 1, 29, null),
             (83, 'R1', 1, 29, null),

             -- - Wardrobe WC
             -- - - Close
             (84, '1', 0, 32, null),
             (85, '2', 0, 32, null),
             (86, '3', 1, 32, null),
             (87, '4', 1, 32, null),
             (88, '5', 2, 32, null),
             (89, '6', 2, 32, null),

             -- - - Distant
             (90, 'L2', 0, 33, null),
             (91, 'L1', 0, 33, null),
             (92, 'R3', 1, 33, null),
             (93, 'R2', 1, 33, null),
             (94, 'R1', 1, 33, null)) as t(id, name, column_index, parent_id, row_index)
WHERE l.id = t.id;

COMMIT;
-- +goose StatementEnd
