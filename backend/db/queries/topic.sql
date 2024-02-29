-- name: SubscribeToTopic :exec
INSERT INTO user_topic (user_id, topic_id)
VALUES ($1, (SELECT id FROM topic WHERE name = $2))
ON CONFLICT DO NOTHING;

-- name: UnsubscribeFromTopic :exec
DELETE
FROM user_topic
WHERE user_id = $1
  AND topic_id = (SELECT id FROM topic WHERE name = $2);

-- name: GetAllTopics :many
SELECT *
FROM topic;

-- name: HasUserTopic :one
SELECT EXISTS(SELECT *
              FROM user_topic ut
                       LEFT JOIN topic t ON ut.topic_id = t.id
              WHERE ut.user_id = $1);

-- name: GetTopicsByUserID :many
SELECT t.name
FROM topic t
         LEFT JOIN user_topic ut ON t.id = ut.topic_id
WHERE ut.user_id = $1;
