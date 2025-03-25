WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY visitor_id
),

last_paid AS (
    SELECT
        s.visitor_id,
        s.visit_date::date,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.status_id
    FROM sessions AS s
    INNER JOIN tab AS t
        ON s.visit_date = t.last_visit AND s.visitor_id = t.visitor_id
    LEFT JOIN leads AS l
        ON s.visit_date <= l.created_at AND s.visitor_id = l.visitor_id
),

ads AS (
    SELECT
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS spent
    FROM vk_ads
    GROUP BY
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign
    UNION ALL
    SELECT
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS spent
    FROM ya_ads
    GROUP BY
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign
)

SELECT
    lp.visit_date::date,
    lp.utm_source,
    lp.utm_medium,
    lp.utm_campaign,
    COUNT(DISTINCT lp.visitor_id) AS visitors_count,
    COALESCE((a.spent)::text, '') AS total_cost,
    COUNT(DISTINCT lp.lead_id) AS leads_count,
    COUNT(DISTINCT lp.lead_id) FILTER (
        WHERE lp.status_id = 142
    ) AS purchases_count,
    SUM(lp.amount) AS revenue
FROM last_paid AS lp
LEFT JOIN ads AS a
    ON
        lp.visit_date = a.campaign_date
        AND lp.utm_source = a.utm_source
        AND lp.utm_medium = a.utm_medium
        AND lp.utm_campaign = a.utm_campaign
GROUP BY
    lp.visit_date,
    lp.utm_source,
    lp.utm_medium,
    lp.utm_campaign,
    a.spent
ORDER BY
    revenue DESC NULLS LAST,
    lp.visit_date ASC,
    visitors_count DESC,
    lp.utm_source ASC,
    lp.utm_medium ASC,
    lp.utm_campaign ASC
