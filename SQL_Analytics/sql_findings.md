# SQL Findings: Lending Club Loan Portfolio (36-month loans, 2013-2015)

## Data and scope
- Source: Lending Club accepted loans (US data), 36-month loans issued 2013-2015 with a final outcome (Fully Paid or Charged Off/Default).
- 546,018 loans, USD 6,942.4M disbursed, overall default rate 14.07%.
- Default is defined as Charged Off or Default. Loans still in progress were excluded.
- Tools: MySQL 8, queries saved in the `/sql` folder.

## Finding 1: Risk rises steadily with Lending Club's grade
- Default rate climbs from 5.29% in grade A to 41.46% in grade G (Query 02).
- Grades A-C hold most of the exposure, so the portfolio's overall risk depends mainly on these three grades.
- Caveat: grade G has only 439 loans, so its rate is less reliable than the others.

## Finding 2: Lower income means higher default
- Default falls from 19.29% for incomes under 40k to 9.62% for incomes of 130k and above (Query 04).
- Income is a usable risk factor and should be considered in the scorecard.
- Caveat: income is self-reported and was partly verified, so treat it with care.

## Finding 3: Loan purpose matters
- Small business loans are the riskiest at 22.93%, followed by moving at 19.92%. Credit card refinancing is the safest at 11.75% (Query 03).
- Debt consolidation is the largest purpose by volume (313,370 loans) at 14.74%, close to the portfolio average.
- A lender could apply stricter terms to small business loans.

## Finding 4: Default rates rise over time
Grade mix shifted toward safer grades (grade A rose from 17.0% to 24.8% of loans), so the rise is not explained by mix. Default rates rose within almost every grade (for example grade C from 15.3% to 19.4%), which suggests Lending Club’s grades became less accurate or underwriting weakened inside each grade. This split is approximate and is not proof of the cause.

## Finding 5: Geographic variation
- Among states with at least 1,000 loans, Mississippi has the highest default rate (18.72%), followed by Arkansas (17.48%) and Nevada (17.42%) (Query 06).
- Caveat: state is not used as a model variable because of fairness concerns and weak evidence of causation.

## Finding 6: Riskiest segments
- The highest-loss segment is grade F with debt consolidation (39.89% simplified loss), followed by grade E small business (33.64%) and grade E credit card (33.44%) (Query 07).
- Segments combining low grades with common purposes are where losses concentrate, so they are candidates for policy tightening.

## Finding 7: Pricing check (simplified)
- Interest rate minus simplified lifetime loss is +2.06 points for grade A, -0.17 for grade B, and falls to -15.99 for grade G (Query 08).
- Caveat: this overstates the shortfall. The interest rate is annual while the loss is over the loan's full life, the loss ignores recoveries and repayments before default, and dividing by 3 years would understate the loss. The real answer lies between the two.
- A proper profitability check needs actual payment data and is a later step.

## Limitations
- US peer-to-peer data, not Indian lending data.
- Default is a simplified outcome definition.
- Results are descriptive. They show patterns, not causes.

## Next steps
Python EDA and cleaning, then a WOE/IV logistic regression scorecard tested on 2015 loans.
