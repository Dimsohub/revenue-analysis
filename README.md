# Revenue Analysis
## Introduction

This project presents an in-depth analysis of revenue trends between March and December 2022. The data used in this analysis was extracted using an SQL query and then visualized using Tableau to provide clear and insightful representations of the findings.

**The analysis focuses on answering the following key questions:**

* **Factors influencing revenue:**  How do new user acquisition and customer churn affect overall revenue?
* **Revenue trends over time:** Are there noticeable patterns of growth, decline, or stability in revenue throughout the analyzed period?
* **Conclusions and recommendations:** What actionable insights can be derived from the analysis to improve revenue performance?
## Data Sources

The data for this project was extracted from a PostgreSQL database containing two primary tables:

![ER_diagrams.png]

* **games_paid_users:** Contains information about users who have made in-app purchases, including their user ID, game name, language, device model (whether it's an older model), and age.
* **games_payments:** Contains information about payments made within the games, including the user ID, game name, payment date, and revenue amount in USD.
