WITH tab AS (
	SELECT visitor_id, MAX(visit_date) AS last_visit
	FROM sessions 
	WHERE medium != 'organic'
	GROUP BY 1 
) 

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
INNER JOIN tab AS t ON s.visit_date = t.last_visit AND s.visitor_id = t.visitor_id
LEFT JOIN leads AS l ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
ORDER BY 
	l.amount DESC NULLS LAST, 
	s.visit_date ASC, 
	s.source ASC,
	s.medium ASC, 
	s.campaign ASC
