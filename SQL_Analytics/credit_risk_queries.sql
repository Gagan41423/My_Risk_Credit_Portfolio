# CREATING DATABASES AND CHECKING DATA TYPES TO ALTER AND MODIFY THE TYPES AND ADDING PRIMARY KEYS FOR SQL QUERIES FLUENCY

SELECT version();
CREATE DATABASE ic_project;
USE ic_project;
DESCRIBE loans;

ALTER TABLE loans
  MODIFY grade CHAR(1),
  MODIFY sub_grade CHAR(2),
  MODIFY addr_state CHAR(2),
  MODIFY home_ownership VARCHAR(20),
  MODIFY verification_status VARCHAR(20),
  MODIFY loan_status VARCHAR(20),
  MODIFY purpose VARCHAR(30),
  MODIFY earliest_cr_line VARCHAR(10),
  MODIFY application_type VARCHAR(20),
  MODIFY bad TINYINT,
  MODIFY never_delinq_flag TINYINT;

ALTER TABLE loans ADD PRIMARY KEY (id);
CREATE INDEX idx_grade ON loans (grade);
CREATE INDEX idx_issue_d ON loans (issue_d);
CREATE INDEX idx_purpose ON loans (purpose);
CREATE INDEX idx_state ON loans (addr_state);

# USED PYTHON CODE TO LOAD THE DATA IN SQL WITH SQLALCHEMY WITH PROPER DATA TYPE CHECKS WITH AUTO 
# TABLE CREATION BY PYTHON AND ALSO MODIFY IT HERE ABOVE FOR MORE CLEAN SQL USECASE

SELECT COUNT(*), ROUND(100*AVG(bad),2), ROUND(AVG(int_rate),2) FROM loans;


# RUNNING SQL ADVANCE ANALYTICS QUERIES FOR LOAN DATASET

# PORTFOLIO SUMMARY 

SELECT COUNT(*) AS loans,
      ROUND(SUM(loan_amnt) / 1e6,1 ) AS disbursed_millions,
      ROUND(AVG(int_rate),2) AS avg_int_pct,
      ROUND(100.0 * AVG(bad),2) AS default_rate_pct
FROM loans;


# Business Question - Does Risk Rise With Grade, and where is the money-

SELECT grade,
       COUNT(*) AS loans,
       ROUND(SUM(loan_amnt) / 1e6 , 2) AS disbursed_millions, 
       ROUND(AVG(BAD) * 100.0,2) AS default_rate_pct,
       ROUND(AVG(int_rate),2) AS avg_int_pct
FROM loans
GROUP BY grade
ORDER BY grade;


# Business Question - Which Loan Purpose is the Riskiest

SELECT purpose,
       count(*) as loans,
       ROUND(100.0 * AVG(bad), 2) AS default_rate_pct
FROM loans
GROUP BY purpose
HAVING COUNT(*) >= 1000
ORDER BY default_rate_pct;

# Business Question - Do Lower Income Borrowers Deafult More-

SELECT CASE WHEN income < 40000 THEN '1. under 40k'
            WHEN income < 60000 THEN '2. 40k to 60K'
            WHEN income < 90000 THEN '3. 60k to 90k'
            WHEN income < 130000 THEN '4 90k to 130k'
       ELSE '5. 130k+' END AS income_band,
       COUNT(*) AS loans,
       ROUND(100.0*AVG(bad) ,2) AS default_rate_pct
FROM loans
GROUP BY income_band
ORDER BY income_band;


# Business Questions - Is Credit Quality is getting Better or Worse Over Time- 

SELECT YEAR(issue_d) AS issue_year,
       QUARTER(issue_d) AS qtr,
       count(*) AS loans,
       ROUND(AVG(bad)* 100.0 ,2) as default_rate_pct
FROM loans 
GROUP BY YEAR(issue_d), QUARTER(issue_d)
ORDER BY issue_year, qtr;


# WHICH SATES HAVE THE HIGHEST DEFAULT RATE (MINIMUM 1000 LOANS)

SELECT addr_state ,
       COUNT(*) as loans,
       ROUND(AVG(bad) * 100.0, 2) AS deafult_rate_pct,
       RANK() OVER( ORDER BY AVG(bad) DESC) AS risk_rank
FROM loans 
GROUP BY addr_state
HAVING COUNT(*) >= 1000
ORDER BY risk_rank;


# BUSINESS QUESTION - GRADE + PURPOSE SEGMENTS CARRY THE HIGHEST LOSS -

WITH seg AS (
         SELECT grade, purpose,
		       COUNT(*) AS loans,
			   SUM(loan_amnt) AS exposure,
               SUM( loan_amnt * bad) AS charged_off_amount,
               AVG(bad) AS default_rate
FROM loans 
GROUP BY grade, purpose
HAVING COUNT(*) >= 500
)
               
SELECT grade, purpose, loans, 
       ROUND( exposure / 1e6, 1) AS exposure_millions,
       ROUND(100.0 * default_rate, 2) AS default_rate_pct,
       ROUND( 100.0 * charged_off_amount / exposure, 2) AS loss_rate_pct
FROM seg
ORDER BY loss_rate_pct DESC
LIMIT 10 ;
       
                       
# BUSINESS QUESTION - DOES THE INTEREST RATE CHARGED COVER THE CHARGES OF LOSS ON EACH GRADE-

SELECT grade,
       ROUND(AVG(int_rate),2) AS avg_int_rate,
       ROUND(100.0 * SUM(loan_amnt * bad) / SUM(loan_amnt),2) AS simplified_loss_pct,
       ROUND(AVG(int_rate) - 100.0 * SUM(loan_amnt * bad)/ SUM(loan_amnt), 2) AS gap
FROM loans 
GROUP BY grade
ORDER BY grade;

# Caveat for Query 8: this is a simplified screen. The interest rate is annual, while the loss is over the whole loan life.
# The loss figure also assumes the full principal is lost on a default, 
# ignoring recoveries and what was repaid before default. So a negative gap does not mean Lending Club lost money.

      
      

       


       