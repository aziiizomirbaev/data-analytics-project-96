WITH tab AS (
	SELECT 
		s.visitor_id,
		s.visit_date, 
		s.source AS utm_source, 
		s.medium AS utm_medium, 
		s.campaign AS utm_campaign, 
		l.lead_id, 
		l.amount, 
		l.closing_reason, 
		l.status_id, 
		ROW_NUMBER() OVER(PARTITION BY s.visitor_id ORDER BY s.visit_date DESC) AS last_click 
	FROM sessions AS s 
	LEFT JOIN leads AS l ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
	WHERE s.medium IN ('cpc', 'cpm', 'cpa', 'cpp', 'tg', 'youtube', 'social')
) 
SELECT 
	visitor_id,
	visit_date, 
	utm_source, 
	utm_medium, 
	utm_campaign, 
	lead_id, 
	amount, 
	closing_reason, 
	status_id
FROM tab 
WHERE last_click = 1 
ORDER BY 
	amount DESC NULLS LAST, 
	visit_date ASC, 
	utm_source ASC, 
	utm_medium ASC, 
	utm_campaign ASC;
