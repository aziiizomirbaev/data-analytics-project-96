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
