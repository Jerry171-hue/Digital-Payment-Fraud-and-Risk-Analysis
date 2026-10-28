create database digital_payment_risk;

use digital_payment_risk;


create table transactions (
    transaction_id varchar(50) primary key,
    user_id varchar(50),
    transaction_amount decimal(12,2),
    transaction_type varchar(50),
    payment_mode varchar(50),
    device_type varchar(50),
    device_location varchar(100),
    account_age_days int,
    transaction_hour int,
    previous_failed_attempts int,
    avg_transaction_amount decimal(12,2),
    is_international int,
    ip_risk_score decimal(5,3),
    login_attempts_last_24h int,
    fraud_label int,
    amount_category varchar(20),
    account_age_category varchar(20),
    failed_attempt_category varchar(20),
    ip_risk_category varchar(20),
    login_attempt_category varchar(20),
    risk_level varchar(20)
);


-- Data Quality Checks
 
-- Row count
select COUNT(*) as total_transactions
from transactions;


-- Preview
select * from transactions
limit 10;


-- Total number of duplicated IDs
select COUNT(*) as duplicate_ids
from (
select transaction_id
FROM transactions
group by transaction_id
having COUNT(*) > 1
) as duplicates;


-- NULL check for important fields
select SUM(transaction_id is null) as null_transaction_id,
SUM(user_id is null) as null_user_id,
SUM(transaction_amount is null) as null_transaction_amount,
SUM(transaction_type is null) as null_transaction_type,
SUM(payment_mode is null) as null_payment_mode,
SUM(device_type is null) as null_device_type,
SUM(device_location is null) as null_device_location,
SUM(account_age_days is null) as null_account_age,
SUM(transaction_hour is null) as null_transaction_hour,
SUM(previous_failed_attempts is null) as null_failed_attempts,
SUM(ip_risk_score is null) as null_ip_risk,
SUM(login_attempts_last_24h is null) as null_login_attempts,
SUM(fraud_label is null) as null_fraud_label
from transactions;


-- Check numeric ranges
select MIN(transaction_amount) as min_transaction_amount,
MAX(transaction_amount) as max_transaction_amount,
MIN(account_age_days) as min_account_age_days,
MAX(account_age_days) as max_account_age_days,
MIN(transaction_hour) as min_transaction_hour,
MAX(transaction_hour) as max_transaction_hour,
MIN(previous_failed_attempts) as min_failed_attempts,
MAX(previous_failed_attempts) as max_failed_attempts,
MIN(ip_risk_score) as min_ip_risk_score,
MAX(ip_risk_score) as max_ip_risk_score,
MIN(login_attempts_last_24h) as min_login_attempts,
MAX(login_attempts_last_24h) as max_login_attempts
from transactions;


-- Fraud label distribution
select fraud_label,
COUNT(*) as transactions
from transactions
group by fraud_label
order by fraud_label;


-- Cleaned Analytical View

-- The source contains NULL failed_attempt_category values.
-- For this dataset, those records correspond to zero failed
-- attempts, so the analytical view labels them as 'None'.

create or replace view transaction_clean as
select transaction_id, user_id, transaction_amount, transaction_type, payment_mode, device_type,
device_location, account_age_days, transaction_hour, previous_failed_attempts,
avg_transaction_amount, is_international, ip_risk_score, login_attempts_last_24h, fraud_label,
amount_category, account_age_category,
case when previous_failed_attempts = 0 
then 'None'
else failed_attempt_category
end as failed_attempt_category, ip_risk_category, login_attempt_category,

    -- Keep the original dataset classification for comparison.
risk_level as source_risk_level
from transactions;


-- Verify cleaned view
select * from transaction_clean
limit 10;


-- executive analyses
 
-- Overall transaction KPIs

select
COUNT(*) as total_transactions,
ROUND(SUM(transaction_amount), 2) as total_transaction_value,
ROUND(AVG(transaction_amount), 2) as average_transaction_value,
ROUND(MIN(transaction_amount), 2) as minimum_transaction_value,
ROUND(MAX(transaction_amount), 2) as maximum_transaction_value
from transaction_clean;


-- Overall fraud KPIs

select SUM(fraud_label) as fraudulent_transactions,
COUNT(*) - SUM(fraud_label) as legitimate_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate,
ROUND( SUM( case when fraud_label = 1 then transaction_amount
else 0
end), 2) as fraudulent_transaction_value
from transaction_clean;


-- Fraud by Payment & Transactions Behaviour 

-- Fraud by payment mode

select payment_mode,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate,
ROUND(SUM(transaction_amount), 2) as transaction_value
from transaction_clean
group by payment_mode
order by fraud_rate desc;


-- 6.2 Fraud by transaction type

select transaction_type,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
group by transaction_type
order by fraud_rate desc;


-- 6.3 Fraud by device type

select device_type,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
group by device_type
order by fraud_rate desc;


-- 6.4 Fraud by transaction hour

select transaction_hour,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
group by transaction_hour
order by fraud_rate desc;


-- 6.5 Fraud by international vs domestic

select
case when is_international = 1 then 'International'
else 'Domestic'
end as transaction_scope,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2 ) as fraud_rate
from transaction_clean
group by is_international
order by fraud_rate desc;



-- Fraud & Risk Factor Analysis 


-- Fraud by IP risk category

select ip_risk_category,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
group by ip_risk_category
order by fraud_rate desc;


-- Fraud by previous failed attempts

select failed_attempt_category,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*),2) as fraud_rate
from transaction_clean
group by failed_attempt_category
order by fraud_rate desc;


-- 7.3 Fraud by login-attempt category

select login_attempt_category,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
group by login_attempt_category
order by fraud_rate desc;


-- Fraud by account-age category

select account_age_category,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
group by account_age_category
order by fraud_rate desc;


-- Fraud by transaction amount category

select amount_category,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate,
ROUND(SUM(transaction_amount), 2) as transaction_value
from transaction_clean
group by amount_category
order by fraud_rate desc;


-- SECTION 8: RULE-BASED RISK SCORING MODEL


create or replace view transaction_risk_scored as
select
    t.*,

    -- 1. IP risk points
case when ip_risk_score >= 0.80 then 30
when ip_risk_score >= 0.60 then 20
when ip_risk_score >= 0.30 then 10
else 5
end as ip_risk_points,

    -- 2. Failed-attempt points
case when previous_failed_attempts >= 4 then 25
when previous_failed_attempts >= 2 then 15
when previous_failed_attempts = 1 then 10
else 5
end as failed_attempt_points,

    -- 3. Login-attempt points
case when login_attempts_last_24h >= 8 then 20
when login_attempts_last_24h >= 5 then 15
when login_attempts_last_24h >= 3 then 10
else 5
end as login_risk_points,

    -- 4. Account-age points
case when account_age_days <= 30 then 15
when account_age_days <= 90 then 10
else 5
end as account_age_points,

    -- 5. International transaction points
case when is_international = 1 then 10
else 0
end as international_points
from transaction_clean as t;



-- Final Calculated risk Score

create or replace view transaction_risk_final as
select
    *,
    (ip_risk_points + failed_attempt_points + login_risk_points + account_age_points + international_points) as calculated_risk_score,
case when (ip_risk_points + failed_attempt_points + login_risk_points + account_age_points + international_points) >= 85 then 'Critical'
when (ip_risk_points + failed_attempt_points + login_risk_points + account_age_points + international_points) >= 70 then 'High'
when (ip_risk_points + failed_attempt_points + login_risk_points + account_age_points + international_points ) >= 45 then 'Medium'
else 'Low'
end as calculated_risk_level
from transaction_risk_scored;



-- Risk Validation


-- Check calculated score range

select
MIN(calculated_risk_score) as minimum_score,
MAX(calculated_risk_score) as maximum_score,
ROUND(AVG(calculated_risk_score), 2) as average_score
from transaction_risk_final;


-- Distribution of calculated risk

select calculated_risk_level,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2 ) as fraud_rate,
ROUND(SUM(case when fraud_label = 1
then transaction_amount
else 0
end ), 2) as fraud_value
from transaction_risk_final
group by calculated_risk_level
order by case calculated_risk_level 
when 'Critical' then 1
when 'High' then 2
when 'Medium' then 3
when 'Low' then 4
end;


-- Compare source risk level with actual fraud

select source_risk_level,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*),2 ) as fraud_rate,
ROUND( SUM(case when fraud_label = 1 then transaction_amount
else 0
end), 2) as fraud_value
from transaction_risk_final
group by source_risk_level
order by fraud_rate desc;


-- 10.4 Compare calculated risk with actual fraud

select calculated_risk_level,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_risk_final
group by calculated_risk_level
order by case calculated_risk_level when 'Critical' then 1
when 'High' then 2
when 'Medium' then 3
when 'Low' then 4
end;


-- SECTION 11: HIGH-RISK TRANSACTION INVESTIGATION


-- 11.1 Highest-risk transactions

select transaction_id, user_id, transaction_amount, payment_mode, device_type,
ip_risk_score, previous_failed_attempts, login_attempts_last_24h,
is_international, calculated_risk_score, calculated_risk_level,
source_risk_level, fraud_label
from transaction_risk_final
order by calculated_risk_score desc,
transaction_amount desc
limit 10;


-- High/Critical transactions that were actually fraudulent

select transaction_id, user_id, transaction_amount, payment_mode, device_type, ip_risk_score,
previous_failed_attempts, login_attempts_last_24h, is_international, calculated_risk_score,
calculated_risk_level, fraud_label
from transaction_risk_final
where calculated_risk_level in ('High', 'Critical')
and fraud_label = 1
order by calculated_risk_score desc;


-- High/Critical risk performance

select COUNT(*) as high_risk_transactions,
SUM(fraud_label) as high_risk_fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as high_risk_fraud_rate,
ROUND(SUM( case when fraud_label = 1 then transaction_amount
else 0
end ), 2)as high_risk_fraud_value
from transaction_risk_final
where calculated_risk_level in ('High', 'Critical');



-- SECTION 12: PAYMENT MODE + RISK ANALYSIS

select payment_mode,calculated_risk_level,
COUNT(*) as transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate,
ROUND(SUM(transaction_amount), 2) as transaction_value
from transaction_risk_final
group by payment_mode,
calculated_risk_level
order by fraud_rate desc;



-- SECTION 13: INTERNATIONAL + RISK ANALYSIS


select
case when is_international = 1 then 'International'
else 'Domestic'
end as transaction_scope,
calculated_risk_level,
COUNT(*) as transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*),2 ) as fraud_rate
from transaction_risk_final
group by is_international,
calculated_risk_level
order by transaction_scope,
fraud_rate desc;


-- user level fraud analysis

select user_id,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate,
ROUND( SUM( case when fraud_label = 1 then transaction_amount
else 0
end), 2) as fraudulent_value
from transaction_risk_final
group by user_id
having SUM(fraud_label) > 0
order by fraud_transactions desc,
fraudulent_value desc
limit 20;



-- SECTION 15: TOP FRAUD VALUE TRANSACTIONS

select transaction_id, user_id, transaction_amount, payment_mode, transaction_type,
device_type, ip_risk_score, calculated_risk_score, calculated_risk_level, fraud_label
from transaction_risk_final
WHERE fraud_label = 1
order by transaction_amount desc
limit 20;





-- Business Focused Fraud Analysis 

-- Which payment mode has the highest fraud rate?

select payment_mode,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND( SUM(fraud_label) * 100.0 / COUNT(*), 2 ) as fraud_rate
from transaction_clean
group by payment_mode
order by fraud_rate desc;


-- Which transaction type has the highest fraud rate?

select transaction_type,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*),2) as fraud_rate
from transaction_clean
group by transaction_type
order by fraud_rate desc;


-- Which device has the highest fraud rate?

select device_type,
COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
group by device_type
order by fraud_rate desc;


-- What is the highest-risk transaction hour?

select transaction_hour,
COUNT(*) as total_transactions, 
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*),2) as fraud_rate
from transaction_clean
group by transaction_hour
order by fraud_rate desc
limit 5;


-- What proportion of international transactions are fraudulent?

select
COUNT(*) as international_transactions,
SUM(fraud_label) as fraud_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate
from transaction_clean
where is_international = 1;



-- Power BI Dataset 
-- Connect Power BI to this view.(for better insights)

create or replace view powerbi_risk_dataset as
select transaction_id, user_id, transaction_amount, transaction_type, payment_mode, device_type, device_location, account_age_days,
transaction_hour, previous_failed_attempts, avg_transaction_amount, is_international, ip_risk_score, login_attempts_last_24h, fraud_label,
amount_category, account_age_category, failed_attempt_category, ip_risk_category, login_attempt_category, ip_risk_points, failed_attempt_points,
login_risk_points, account_age_points, international_points, calculated_risk_score, calculated_risk_level, source_risk_level
from transaction_risk_final;


select * from powerbi_risk_dataset
limit 10;


-- Fraud summary

select COUNT(*) as total_transactions,
SUM(fraud_label) as fraud_transactions,
COUNT(*) - SUM(fraud_label) as legitimate_transactions,
ROUND(SUM(fraud_label) * 100.0 / COUNT(*), 2) as fraud_rate,
ROUND(SUM(case when fraud_label = 1 then transaction_amount
else 0
end ),2) as fraudulent_transaction_value
from powerbi_risk_dataset;


