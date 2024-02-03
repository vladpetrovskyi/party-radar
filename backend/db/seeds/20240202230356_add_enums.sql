-- +goose Up
-- +goose StatementBegin
INSERT INTO element_type (id, name)
VALUES (1, 'root'),
       (2, 'expansionTile'),
       (3, 'listTile'),
       (4, 'card');

INSERT INTO on_click_action (id, name)
VALUES (1, 'select'),
       (2, 'openDialog');

INSERT INTO friendship_status (id, name)
VALUES (1, 'requested'),
       (2, 'accepted'),
       (3, 'rejected');

INSERT INTO post_type (id, name)
VALUES (1, 'start'),
       (2, 'ongoing'),
       (3, 'end');
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DELETE
FROM post_type
WHERE id IN (1, 2, 3);

DELETE
FROM friendship_status
WHERE id IN (1, 2, 3);

DELETE
FROM on_click_action
WHERE id IN (1, 2);

DELETE
FROM element_type
WHERE id IN (1, 2, 3, 4);
-- +goose StatementEnd
