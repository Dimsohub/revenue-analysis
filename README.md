# Revenue Analysis
## Introduction

This project presents an in-depth analysis of revenue trends between March and December 2022. The data used in this analysis was extracted using an SQL query and then visualized using Tableau to provide clear and insightful representations of the findings.

**The analysis focuses on answering the following key questions:**

* **Factors influencing revenue:**  How do new user acquisition and customer churn affect overall revenue?
* **Revenue trends over time:** Are there noticeable patterns of growth, decline, or stability in revenue throughout the analyzed period?
* **Conclusions and recommendations:** What actionable insights can be derived from the analysis to improve revenue performance?
## Data Sources

The data for this project was extracted from a PostgreSQL database containing two primary tables:

![ER_diagrams.png](ER_diagrams.png)

* **games_paid_users:** Contains information about users who have made in-app purchases, including their user ID, game name, language, device model (whether it's an older model), and age.
* **games_payments:** Contains information about payments made within the games, including the user ID, game name, payment date, and revenue amount in USD.
## Tools

The following tools were used in this project:

* **DBeaver:** A free and open-source universal database tool used to connect to the PostgreSQL database, query the data, and export it for analysis.
* **Tableau Public:** A free platform for creating interactive data visualizations. Tableau Public was used to create charts and dashboards to analyze and present the revenue data.
## SQL Query

The following SQL query was used to extract and prepare the data for analysis:

~~~SQL
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
        CASE 
            WHEN LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
            THEN total_revenue 
            ELSE 0
        END AS new_mrr,
        CASE 
            WHEN LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
            THEN 1 
            ELSE 0
        END AS new_users,
        CASE 
            WHEN (LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
                AND payment_month < MAX(payment_month) OVER ()) 
                OR (LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) != DATE(payment_month + INTERVAL '1' MONTH))
            THEN 1 
            ELSE 0
        END AS churn_users,
        CASE 
            WHEN MAX(payment_month) OVER (PARTITION BY user_id) = payment_month 
            THEN total_revenue 
            ELSE 0
        END AS churn_revenue,
        CASE 
            WHEN LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) IS NULL 
                OR LEAD(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) != DATE(payment_month + INTERVAL '1' MONTH)
            THEN total_revenue 
            ELSE 0
        END AS churned_revenue,
        CASE 
            WHEN LAG(payment_month) OVER (PARTITION BY user_id ORDER BY payment_month) = DATE(payment_month - INTERVAL '1' MONTH) 
                AND total_revenue > LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month) 
            THEN total_revenue - LAG(total_revenue) OVER (PARTITION BY user_id ORDER BY payment_month)
            ELSE 0
        END AS expansion_revenue,
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
~~~
**Comments:**

This SQL query performs the following actions:

*   **Creates CTE `monthly_revenue`:**
    *   Calculates the total revenue (`total_revenue`) for each user (`user_id`) in each game (`game_name`) for each month (`payment_month`).
    *   Uses `DATE_TRUNC('month', payment_date)` to group payments by month.

*   **Creates CTE `calculated_metrics`:**
    *   Adds additional metrics to `monthly_revenue` using window functions:
        *   `previous_paid_month`: Date of the user's previous payment.
        *   `previous_paid_month_revenue`: Revenue from the user's previous payment.
        *   `last_paid_month`: Date of the user's last payment.
        *   `next_paid_month`: Date of the user's next payment.
        *   `next_calendar_month`: The next calendar month after the current `payment_month`.
        *   `new_mrr`: New monthly recurring revenue (MRR) from users making their first purchase.
        *   `new_users`: Number of new users in the month.
        *   `churn_users`: Number of users who churned in this month and did not return.
        *   `churn_revenue`: Revenue from users who churned in this month.
        *   `churned_revenue`: Revenue lost due to gaps between payments or no future payments.
        *   `expansion_revenue`: Increase in MRR compared to the previous month.
        *   `contraction_revenue`: Decrease in MRR compared to the previous month.

*   **Joins `calculated_metrics` with `games_paid_users`:**
    *   Joins the data on `user_id` to add information about the user's language (`language`) and age (`age`) to the calculated metrics.

The query returns a table with data about users, their payments, and various revenue-related metrics.


