WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY visitor_id  
)

SELECT * 
FROM tab;

WITH result AS (
    SELECT
        s.visitor_id,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.closing_reason,
        l.status_id,
        COALESCE(l.amount, 0) AS amount,
        TO_CHAR(s.visit_date, 'YYYY-MM-DD HH24:MI:SS.MS') AS visit_date,
        TO_CHAR(l.created_at, 'YYYY-MM-DD HH24:MI:SS.MS') AS created_at
    FROM sessions AS s
    INNER JOIN tab AS t
        ON s.visit_date = t.last_visit AND s.visitor_id = t.visitor_id
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
)

SELECT *
FROM result
ORDER BY
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC, 
    utm_medium ASC, 
    utm_campaign ASC; 
