-- CREDIT RISK ANALYSIS — SQL queries ( MySQL Workbench)

--created & selected a database
CREATE DATABASE IF NOT EXISTS credit_risk;
USE credit_risk;


-- created the table
DROP TABLE IF EXISTS loans;
CREATE TABLE loans (
    issue_year          INT,
    loan_amnt           DECIMAL(12,2),
    term                INT,
    int_rate            DECIMAL(6,2),
    installment         DECIMAL(12,2),
    grade               VARCHAR(2),
    sub_grade           VARCHAR(3),
    emp_length          DECIMAL(4,1),
    home_ownership      VARCHAR(20),
    annual_inc          DECIMAL(14,2),
    income_band         VARCHAR(20),
    verification_status VARCHAR(30),
    purpose             VARCHAR(40),
    addr_state          VARCHAR(2),
    dti                 DECIMAL(8,2),
    dti_band            VARCHAR(10),
    fico                DECIMAL(6,1),
    revol_util          DECIMAL(6,2),
    delinq_2yrs         INT,
    loan_status         VARCHAR(20),
    is_default          INT,
    risk_score          INT,
    risk_segment        VARCHAR(10)
);


-- loaded the CSV 

LOAD DATA INFILE '/credit_risk_clean.csv'
INTO TABLE loans
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@issue_year, loan_amnt, term, int_rate, installment, grade, sub_grade,
 @emp_length, home_ownership, annual_inc, income_band, verification_status,
 purpose, addr_state, @dti, dti_band, @fico, @revol_util, @delinq_2yrs,
 loan_status, is_default, risk_score, risk_segment)
SET issue_year = NULLIF(@issue_year, ''),
    emp_length = NULLIF(@emp_length, ''),
    dti        = NULLIF(@dti, ''),
    fico       = NULLIF(@fico, ''),
    revol_util = NULLIF(@revol_util, ''),
    delinq_2yrs= NULLIF(@delinq_2yrs, '');


-- verified the load 
SELECT COUNT(*) AS rows_loaded FROM loans;     -- expect 1,345,350
SELECT * FROM loans LIMIT 10;


-- ANALYSIS QUERIES

-- Q1. Overall default rate (the headline KPI)
SELECT
    COUNT(*)                              AS total_loans,
    SUM(is_default)                       AS defaults,
    ROUND(100 * AVG(is_default), 2)       AS default_rate_pct
FROM loans;


-- Q2. Default rate by grade (should rise A -> G)
SELECT
    grade,
    COUNT(*)                        AS loans,
    ROUND(100 * AVG(is_default), 2) AS default_rate_pct,
    ROUND(AVG(int_rate), 2)         AS avg_int_rate
FROM loans
GROUP BY grade
ORDER BY grade;


-- Q3. Default rate by loan purpose (riskiest first)
SELECT
    purpose,
    COUNT(*)                        AS loans,
    ROUND(100 * AVG(is_default), 2) AS default_rate_pct
FROM loans
GROUP BY purpose
HAVING COUNT(*) > 500          -- ignore tiny categories
ORDER BY default_rate_pct DESC;


-- Q4. Default rate by DTI band
SELECT
    dti_band,
    COUNT(*)                        AS loans,
    ROUND(100 * AVG(is_default), 2) AS default_rate_pct
FROM loans
WHERE dti_band IS NOT NULL
GROUP BY dti_band
ORDER BY dti_band;


-- Q5. Default rate by income band
SELECT
    income_band,
    COUNT(*)                        AS loans,
    ROUND(100 * AVG(is_default), 2) AS default_rate_pct
FROM loans
WHERE income_band IS NOT NULL
GROUP BY income_band
ORDER BY default_rate_pct DESC;


-- Q6. Risk segments — the key deliverable
SELECT
    risk_segment,
    COUNT(*)                            AS loans,
    ROUND(100 * AVG(is_default), 2)     AS default_rate_pct,
    ROUND(AVG(int_rate), 2)             AS avg_int_rate,
    ROUND(SUM(loan_amnt), 0)            AS total_exposure
FROM loans
GROUP BY risk_segment
ORDER BY default_rate_pct;


-- Q7. Trend: default rate by year of issue
SELECT
    issue_year,
    COUNT(*)                        AS loans,
    ROUND(100 * AVG(is_default), 2) AS default_rate_pct
FROM loans
WHERE issue_year IS NOT NULL
GROUP BY issue_year
ORDER BY issue_year;


-- Q8. Top 10 states by default rate (min 1000 loans)
SELECT
    addr_state,
    COUNT(*)                        AS loans,
    ROUND(100 * AVG(is_default), 2) AS default_rate_pct
FROM loans
GROUP BY addr_state
HAVING COUNT(*) >= 1000
ORDER BY default_rate_pct DESC
LIMIT 10;


-- Q9. Two-factor view: grade x term (where does risk stack up?)
SELECT
    grade,
    term,
    COUNT(*)                        AS loans,
    ROUND(100 * AVG(is_default), 2) AS default_rate_pct
FROM loans
GROUP BY grade, term
ORDER BY grade, term;
