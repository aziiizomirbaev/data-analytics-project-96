WITH tab AS (
    SELECT
        visitor_id,
        MAX(visit_date) AS last_visit
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY visitor_id
)

SELECT * FROM tab;

WITH last_paid AS (
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
)

SELECT * FROM last_paid;

WITH ads AS (
    SELECT
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        SUM(daily_spent) AS spent
    FROM vk_ads
    GROUP BY
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content
    UNION ALL
    SELECT
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        SUM(daily_spent) AS spent
    FROM ya_ads
    GROUP BY
        campaign_date::date,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content
)

SELECT * FROM ads;

WITH aggregated AS (
    SELECT
        lp.visit_date::date,
        lp.utm_source,
        lp.utm_medium,
        lp.utm_campaign,
        a.spent AS total_cost,
        COUNT(DISTINCT lp.visitor_id) AS visitors_count,
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
)

SELECT * FROM aggregated;

WITH users AS (
    SELECT
        'visitors' AS metric_name,
        COUNT(visitor_id) AS visit_cnt
    FROM sessions
    UNION ALL
    SELECT
        'unique visitors' AS metric_name,
        COUNT(DISTINCT visitor_id) AS visit_cnt
    FROM sessions
)

SELECT * FROM users;

WITH daily_visits AS (
    SELECT
        visit_date::date,
        COUNT(visitor_id) AS visit_count,
        COUNT(DISTINCT visitor_id) AS unique_visitors_count
    FROM sessions
    GROUP BY visit_date::date
)

SELECT * FROM daily_visits;

WITH daily_chanels AS (
    SELECT
        visit_date::date,
        medium,
        COUNT(medium) AS cnt
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY visit_date::date, medium
    ORDER BY
        visit_date::date ASC,
        cnt DESC
)

SELECT * FROM daily_chanels;

WITH weekly_chanels AS (
    SELECT
        DATE_TRUNC('week', visit_date)::date AS week_num,
        medium,
        COUNT(medium) AS cnt
    FROM sessions
    WHERE medium != 'organic'
    GROUP BY
        DATE_TRUNC('week', visit_date)::date,
        medium
    ORDER BY
        week ASC,
        cnt DESC
)

SELECT * FROM weekly_chanels;

WITH cpu AS (
    SELECT ROUND(SUM(total_cost) / SUM(visitors_count), 2) AS cpu
    FROM aggregated
)

SELECT * FROM cpu;

WITH daily_cpu AS (
    SELECT
        visit_date,
        ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0), 2) AS cpu
    FROM aggregated
    GROUP BY visit_date
    ORDER BY visit_date
)

SELECT * FROM daily_cpu;

WITH cpl AS (
    SELECT ROUND(SUM(total_cost) / SUM(leads_count), 2) AS cpl
    FROM aggregated
)

SELECT * FROM cpl;

WITH daily_cpl AS (
    SELECT
        visit_date,
        ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0), 2) AS cpl
    FROM aggregated
    GROUP BY visit_date
    ORDER BY visit_date
)

SELECT * FROM daily_cpl;

WITH cppu AS (
    SELECT ROUND(SUM(total_cost) / SUM(purchases_count), 2) AS cppu
    FROM aggregated
)

SELECT * FROM cppu;

WITH daily_cppu AS (
    SELECT
        visit_date,
        ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0), 2) AS cppu
    FROM aggregated
    GROUP BY visit_date
    ORDER BY visit_date
)

SELECT * FROM daily_cppu;

WITH roi AS (
    SELECT
        utm_medium,
        SUM(revenue) AS total_revenue,
        SUM(total_cost) AS total_cost,
        ROUND(
            (SUM(revenue) - SUM(total_cost)) / NULLIF(SUM(total_cost), 0) * 100,
            2
        ) AS roi
    FROM aggregated
    GROUP BY utm_medium
    ORDER BY roi DESC
)

SELECT * FROM roi;

WITH daily_roi AS (
    SELECT
        visit_date,
        ROUND(
            (SUM(revenue) - SUM(total_cost))
            / NULLIF(SUM(total_cost), 0)
            * 100.00,
            2
        ) AS roi
    FROM aggregated
    GROUP BY visit_date
    ORDER BY visit_date
)

SELECT * FROM daily_roi;

WITH all_metrics AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0), 2) AS cpu,
        ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0), 2) AS cpl,
        ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0), 2) AS cppu,
        ROUND(
            (SUM(revenue) - SUM(total_cost))
            / NULLIF(SUM(total_cost), 0)
            * 100.00,
            2
        ) AS roi
    FROM aggregated
    GROUP BY
        utm_source,
        utm_medium,
        utm_campaign
    ORDER BY
        cpu NULLS LAST,
        cpl NULLS LAST,
        cppu NULLS LAST,
        roi NULLS LAST
)

SELECT * FROM all_metrics;

WITH utm_campaign_cost AS (
    SELECT
        utm_campaign,
        SUM(spent) AS utm_campaign_cost
    FROM ads
    GROUP BY utm_campaign
    ORDER BY utm_campaign_cost DESC
)

SELECT * FROM utm_campaign_cost;

WITH utm_content_cost AS (
    SELECT
        utm_content,
        SUM(spent) AS utm_content_cost
    FROM ads
    GROUP BY utm_content
)

SELECT * FROM utm_content_cost;

WITH utm_medium_cost AS (
    SELECT
        utm_medium,
        SUM(spent) AS utm_medium_cost
    FROM ads
    GROUP BY utm_medium
    ORDER BY utm_medium_cost DESC
)

SELECT * FROM utm_medium_cost;

WITH visit_to_lead AS (
    SELECT
        ROUND(
            (SELECT COUNT(l.lead_id) FROM leads AS l)
            * 100.00
            / COUNT(s.visitor_id),
            2
        ) AS lead_cr
    FROM sessions AS s
)

SELECT * FROM visit_to_lead;

WITH lead_to_purchase AS (
    SELECT
        ROUND(
            COUNT(lead_id) FILTER (WHERE status_id = 142)
            * 100.00
            / COUNT(lead_id),
            2
        ) AS purchase_cr
    FROM leads
)

SELECT * FROM lead_to_purchase;

WITH visit_to_purchase AS (
    SELECT
        ROUND(
            COUNT(l.lead_id) FILTER (WHERE l.status_id = 142)
            * 100.00
            / (SELECT COUNT(s.visitor_id) FROM sessions AS s
            ),
            2
        )
    FROM leads AS l
)

SELECT * FROM visit_to_purchase;

WITH all_cr AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(DISTINCT visitor_id) AS visitors_count,
        COUNT(DISTINCT lead_id) AS leads_count,
        COUNT(
            DISTINCT CASE WHEN status_id = 142 THEN lead_id END
        ) AS purchases_count,
        ROUND(
            100.0
            * COUNT(DISTINCT lead_id)
            / NULLIF(COUNT(DISTINCT visitor_id), 0),
            2
        ) AS cr_click_to_lead,
        ROUND(
            100.0
            * COUNT(DISTINCT CASE WHEN status_id = 142 THEN lead_id END)
            / NULLIF(COUNT(DISTINCT lead_id), 0),
            2
        ) AS cr_lead_to_purchase,
        ROUND(
            100.0
            * COUNT(DISTINCT CASE WHEN status_id = 142 THEN lead_id END)
            / NULLIF(COUNT(DISTINCT visitor_id), 0),
            2
        ) AS cr_click_to_purchase
    FROM last_paid
    GROUP BY
        utm_source,
        utm_medium,
        utm_campaign
    ORDER BY cr_click_to_lead DESC
)

SELECT * FROM all_cr;

WITH lpc_marketing_cnts AS (
    SELECT
        'Visitors' AS metric_name,
        SUM(visitors_count) AS cnt
    FROM all_cr
    UNION ALL
    SELECT
        'Leads' AS metric_name,
        SUM(leads_count) AS cnt
    FROM all_cr
    UNION ALL
    SELECT
        'Paid Users' AS metric_name,
        SUM(purchases_count) AS cnt
    FROM all_cr
)

SELECT * FROM lpc_marketing_cnts;

WITH marketing_cnts AS (
    SELECT
        metric_name,
        visit_cnt
    FROM users
    WHERE metric_name = 'visitors'
    UNION ALL
    SELECT
        'leads' AS metric_name,
        COUNT(lead_id) AS cnt
    FROM leads
    UNION ALL
    SELECT
        'paid_users' AS metric_name,
        COUNT(lead_id) FILTER (WHERE status_id = 142) AS cnt
    FROM leads
)

SELECT * FROM marketing_cnts;

WITH lead_data AS (
    SELECT
        lead_date,
        leads,
        purchases,
        SUM(leads) OVER (
            ORDER BY lead_date
        ) AS cum_lead,
        SUM(purchases) OVER (
            ORDER BY lead_date
        ) AS cum_purchase
    FROM (
        SELECT
            created_at::date AS lead_date,
            COUNT(lead_id) AS leads,
            COUNT(lead_id) FILTER (WHERE status_id = 142) AS purchases
        FROM leads
        GROUP BY created_at::date
    ) AS sub_query
)

SELECT * FROM lead_data;

WITH ninety_percent AS (
    SELECT
        l.lead_date,
        l.cum_lead,
        l.cum_purchase,
        ROUND(
            100.0
            * l.cum_purchase
            / (SELECT SUM(sl.purchases) FROM lead_data AS sl),
            2
        ) AS purchase_percent
    FROM lead_data AS l
)

SELECT * FROM ninety_percent;

WITH ads_spent AS (
    SELECT
        campaign_date,
        SUM(spent) AS spent
    FROM ads
    GROUP BY campaign_date
    ORDER BY campaign_date
)

SELECT * FROM ads_spent;

WITH organic_traffic AS (
    SELECT
        visit_date::date,
        COUNT(visitor_id) AS visit_cnt
    FROM sessions
    GROUP BY visit_date::date
    ORDER BY visit_date::date
)

SELECT * FROM organic_traffic;

WITH correlation AS (
    SELECT CORR(ad.spent, ot.visit_cnt) AS correlation
    FROM ads_spent AS ad
    LEFT JOIN organic_traffic AS ot ON ad.campaign_date = ot.visit_date
)

SELECT * FROM correlation;
