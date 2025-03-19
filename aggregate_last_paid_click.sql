WITH tab AS (
	SELECT visitor_id, MAX(visit_date) AS visit_date
	FROM sessions
	WHERE medium != 'organic'
	GROUP BY 1
), lpc AS (
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
	INNER JOIN tab AS t ON s.visitor_id = t.visitor_id AND s.visit_date = t.visit_date 
	LEFT JOIN leads AS l ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
), last_paid_click_aggregate AS (
	SELECT 
		visit_date::date, 
		utm_source, 
		utm_medium, 
		utm_campaign, 
		COUNT(visitor_id) AS visitors_count, 
		COUNT(lead_id) AS leads_count,
		SUM(CASE WHEN status_id = 142 THEN 1 ELSE 0 END) AS purchases_count, 
		SUM(amount) AS revenue
	FROM lpc 
	GROUP BY 
		visit_date::date, 
		utm_source, 
		utm_medium, 
		utm_campaign 
), ads_cost AS (
	SELECT 
		campaign_date::date, 
		utm_source, 
		utm_medium, 
		utm_campaign,
		SUM(daily_spent) AS total_cost 	
	FROM vk_ads 
	GROUP BY 
		campaign_date::date, 
		utm_source, 
		utm_medium, 
		utm_campaign
	UNION 
	SELECT 
		campaign_date::date, 
		utm_source, 
		utm_medium, 
		utm_campaign,
		SUM(daily_spent) AS total_cost 	
	FROM ya_ads 
	GROUP BY 
		campaign_date::date, 
		utm_source, 
		utm_medium, 
		utm_campaign
)

SELECT 
	lpca.visit_date, 
	lpca.visitors_count, 
	lpca.utm_source, 
	lpca.utm_medium, 
	lpca.utm_campaign, 
	ad.total_cost, 
	lpca.leads_count, 
	lpca.purchases_count, 
	lpca.revenue
FROM last_paid_click_aggregate AS lpca
LEFT JOIN ads_cost AS ad ON 
	lpca.visit_date::date = ad.campaign_date::date
	AND	lpca.utm_source = ad.utm_source
	AND lpca.utm_medium = ad.utm_medium 
	AND lpca.utm_campaign = ad.utm_campaign
ORDER BY 
	lpca.revenue DESC NULLS LAST, 
	lpca.visit_date ASC, 
	lpca.visitors_count DESC, 
	utm_source ASC, 
	utm_medium ASC, 
	utm_campaign ASC
