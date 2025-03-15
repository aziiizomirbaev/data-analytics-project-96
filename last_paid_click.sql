/*
visitor_id — уникальный человек на сайте
visit_date — время визита
utm_source / utm_medium / utm_campaign — метки c учетом модели атрибуции
lead_id — идентификатор лида, если пользователь сконвертился в лид после(во время) визита, NULL — если пользователь не оставил лид
created_at — время создания лида, NULL — если пользователь не оставил лид
amount — сумма лида (в деньгах), NULL — если пользователь не оставил лид
closing_reason — причина закрытия, NULL — если пользователь не оставил лид
status_id — код причины закрытия, NULL — если пользователь не оставил лид
*/

SELECT
    s.visitor_id,
    s.visit_date,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
FROM sessions AS s
LEFT JOIN leads AS l ON s.visitor_id = l.visitor_id
WHERE s.medium != 'organic'
ORDER BY
    l.amount DESC NULLS LAST,
    s.visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC
LIMIT 10;