WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', payment_date)::DATE AS payment_month,
        user_id,
        game_name,
        SUM(revenue_amount_usd) AS total_revenue
    FROM 
        project.games_payments
    GROUP BY 
        1, 2, 3
), 

calculated_metrics AS (
    SELECT 
        mr.*,
        COALESCE(LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month), DATE '1970-01-01') AS previous_paid_month,
        COALESCE(LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month), 0) AS previous_paid_month_revenue,
        MAX(payment_month) OVER (PARTITION BY user_id) AS last_paid_month,
        LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) AS next_paid_month,
        DATE(payment_month + INTERVAL '1' MONTH) AS next_calendar_month,
        
        -- Calculate new MRR (monthly recurring revenue)
        CASE 
            WHEN LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
            THEN total_revenue 
            ELSE 0
        END AS new_mrr,
        
        -- Calculate new users
        CASE 
            WHEN LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
            THEN 1 
            ELSE 0
        END AS new_users,
        
        -- Calculate churned users (users who churned in the current month and did not return)
        CASE 
            WHEN (LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
                AND payment_month < MAX(payment_month) OVER ()) 
                OR (LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) != DATE(payment_month + INTERVAL '1' MONTH))
            THEN 1 
            ELSE 0
        END AS churn_users,
        
        -- Calculate churn revenue (revenue from churned users)
        CASE 
            WHEN MAX(payment_month) OVER (PARTITION BY user_id) = payment_month 
            THEN total_revenue 
            ELSE 0
        END AS churn_revenue,
        
        -- Calculate churned revenue (revenue lost due to gaps between payments or no future payments)
        CASE 
            WHEN LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
                OR LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) != DATE(payment_month + INTERVAL '1' MONTH)
            THEN total_revenue 
            ELSE 0
        END AS churned_revenue,
        
        -- Calculate expansion revenue (increase in MRR from the previous month)
        CASE 
            WHEN LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) = DATE(payment_month - INTERVAL '1' MONTH) 
                AND total_revenue > LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) 
            THEN total_revenue - LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month)
            ELSE 0
        END AS expansion_revenue,
        
        -- Calculate contraction revenue (decrease in MRR from the previous month)
        CASE 
            WHEN LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) = DATE(payment_month - INTERVAL '1' MONTH) 
                AND total_revenue < LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) 
            THEN LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) - total_revenue
            ELSE 0
        END AS contraction_revenue
    FROM 
        monthly_revenue mr
)

SELECT 
    cm.user_id,
    pu.language,
    pu.age,
    cm.payment_month,
    cm.total_revenue,
    cm.new_mrr,
    cm.new_users,
    cm.churn_users,
    cm.churn_revenue,
    cm.churned_revenue,
    cm.expansion_revenue,
    cm.contraction_revenue
FROM 
    calculated_metrics cm
JOIN 
    project.games_paid_users pu
ON 
    cm.user_id = pu.user_id;