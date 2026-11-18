# EDA Findings: Lending Club Loan Portfolio (36-month loans, 2013-2015)

Notebook: `02_eda_cleaning.ipynb` | Input: `lc_clean_v1.parquet` | Output: `lc_clean_v2.parquet`

## 1. Data and scope

- **Population:** 36-month Lending Club loans issued 2013-2015 with a final outcome (Fully Paid, or Charged Off/Default). All of these loans matured before the data ends, so every row has a known result.
- **Size after cleaning:** 546,016 loans, 33 columns, overall default rate 14.07%.
- **Target:** `bad` = 1 for Charged Off or Default, 0 for Fully Paid.
- **Time split planned for modeling:** train on 2013-2014 loans (262,991 loans, 13.19% default), test out-of-time on 2015 loans (283,025 loans, 14.89% default).

## 2. Data preparation decisions

| Step | Decision | Reason |
|---|---|---|
| Missing `emp_length_yrs` (33,601 loans, 6.15%) | Created `emp_missing_flag`, then filled with the median | Missing employment length is itself a risk signal (Finding 1) |
| Missing `mths_since_last_delinq` (49.83%) | Filled with 999 | Missing means no delinquency on record, so a large value is the right meaning. `never_delinq_flag` keeps the same fact separately |
| Missing `utilization` (259 loans), `obligation_ratio` (2 loans) | Median fill | Very small share of rows |
| `income` outliers (max 9,000,000; 99th percentile 250,000) | Capped at the 99th percentile | A few extreme values distort averages and model coefficients |
| `revol_bal` outliers | Capped at the 99th percentile (about 91,815) | Same reason |
| `obligation_ratio` (max 999; 99th percentile 37.4; only 10 loans above 60) | Capped at 40 | Values near 999 are data errors, not real debt-to-income ratios |
| `utilization` (max 892.3; 99th percentile 98.4; 2,192 loans above 100) | Capped at 100 | Above 100 is possible (over the limit) but rare, so capping keeps the variable stable |
| Dropped `term` | Always 36 | No variation, no information |
| Dropped `application_type` | 545,779 Individual vs 239 Joint App | Almost constant |
| Dropped `emp_length` (text) | Replaced by `emp_length_yrs` | Duplicate information |
| Dropped `installment` | Derived from amount, rate and term | Redundant |
| Dropped 2 loans with `home_ownership` = ANY | Too few to analyze | Negligible effect |

## 3. Findings

### Finding 1: Missing employment length is a risk signal
- **Result:** Loans with no employment length recorded default much more often.
- **Evidence:** 20.6% default when employment length is missing (33,601 loans) against 13.6% when it is known.
- **So what:** Filling the blanks without a flag would throw this signal away. `emp_missing_flag` is kept as a model candidate.
- **Caveat:** The data does not say why the field is blank, so this is a correlation and not an explanation.

### Finding 2: Bureau score is the clearest applicant-level risk separator
- **Result:** Default falls steadily as the credit score rises.
- **Evidence:** 19.6% for scores of 665 or below, then 17.4%, 13.8%, 10.4%, 8.0%, and 5.4% for scores above 745. Among the applicant variables checked, `bureau_score` has the strongest correlation with default (-0.12).
- **So what:** It should be a core variable in the scorecard.
- **Caveat:** `bureau_score` is the average of Lending Club's FICO low and high values, so it is a midpoint and not the exact score. The scores only cover roughly 660-850, because Lending Club did not lend below that range.

### Finding 3: Debt-to-income ratio separates risk
- **Result:** Higher `obligation_ratio` (DTI) means higher default.
- **Evidence:** By decile, default rises steadily from 10.5% in the lowest-DTI decile to 20.0% in the highest.
- **So what:** DTI is a strong second variable alongside bureau score, and is easy to map to FOIR in an Indian setting.
- **Caveat:** The ratio was capped at 40, and the top decile's rate is partly driven by the highest values.

### Finding 4: Verified income looks "backwards"
- **Result:** Loans with verified income default more than loans with no verification.
- **Evidence:** Not Verified 11.5% (181,428 loans), Source Verified 14.3% (200,682), Verified 16.6% (163,906).
- **So what:** Verification status should not be read as "verification causes default." A plausible explanation is selection: the lender may have asked for verification on applications it considered riskier. This is a hypothesis, not tested here.
- **Caveat:** Because the relationship is likely driven by the lender's own process, the variable needs careful testing in the model, and may be excluded.

### Finding 5: Short credit history, high utilization and recent enquiries raise risk
- **Result:** Several bureau-type variables move default in the expected direction.
- **Evidence:**
  - Credit history under 5 years: 18.9% default, falling to about 12.0% above 20 years.
  - Revolving utilization: 11.0% at 20% or below, rising to 15.6% at 80-100%.
  - Enquiries in the last 6 months: 12.2% with none (310,864 loans), 20.8% with four or more (9,241 loans).
  - Mortgage accounts: 16.9% with none (235,045 loans), 10.3% with four or more. The pattern is consistent with mortgage holders being more established borrowers, but the data does not test that.
- **So what:** These are good candidates for WOE binning in the scorecard.
- **Caveat:** The four-or-more-enquiries group is small (9,241 loans), so its rate is less stable.

### Finding 6: Home ownership matters
- **Result:** Renters default the most and mortgage holders the least.
- **Evidence:** Mortgage 11.4% (256,254 loans), Own 15.0% (56,988), Rent 16.7% (232,774).
- **So what:** Home ownership is a usable categorical variable.
- **Caveat:** It may partly reflect income and age, which are not fully captured elsewhere.

### Finding 7: Some variables are weak
- **Result:** Not every variable helps.
- **Evidence:** Default by loan-amount quintile does not trend clearly (14.4%, 15.6%, 14.2%, 13.8%, 12.5%). `never_delinq_flag` shows a small gap (14.6% for those with a delinquency record against 13.6% for those with none).
- **So what:** These variables are unlikely to carry much weight in the model. This will be tested with Information Value.
- **Caveat:** A weak single-variable relationship does not rule out usefulness in combination with other variables.

### Finding 8: The rise in default rates is within grades, not from mix
- **Result:** Default rose from 12.3% (2013 loans) to 13.7% (2014) to 14.9% (2015). The increase is not explained by a riskier grade mix.
- **Evidence:** The share of grade A loans rose from 17.0% to 24.8%, and grade B fell from 40.1% to 32.4%, so the portfolio moved toward safer grades. Default rates rose inside most grades: C from 15.3% to 19.4%, D from 20.4% to 26.2%, E from 23.3% to 32.8%. Splitting the 2.56-point rise from 2013 to 2015: mix effect -0.55 points, within-grade effect +3.11 points.
- **So what:** Lending Club's grades became less accurate over time, or underwriting weakened within each grade. This is why the scorecard will be tested out-of-time, on 2015 loans.
- **Caveat:** The split shows where the increase came from, not why. The 2013-2015 data cannot separate changes in borrower quality from changes in economic conditions or lender behavior. The F and G grades have small samples (for example, F is only 0.5% of 2015 loans).

## 4. Correlation with default (numeric variables)

Strongest relationships with `bad`: `int_rate` +0.19 (benchmark only, not a model input), `obligation_ratio` +0.08, `enquiries_6m` +0.07, `bureau_score` -0.12, `income` -0.08, `mort_acc` -0.07. All are modest, which is normal for consumer credit data and suggests a realistic model AUC in the 0.64-0.70 range.

## 5. Leakage control

These fields exist in the full Lending Club file but were deliberately **not loaded**, because they describe what happened after the loan was issued: `out_prncp`, `total_pymnt`, `total_rec_prncp`, `total_rec_int`, `total_rec_late_fee`, `recoveries`, `collection_recovery_fee`, `last_pymnt_d`, `last_pymnt_amnt`, `next_pymnt_d`, `last_fico_range_*`, `last_credit_pull_d`, and all `hardship_*` and `settlement_*` columns.

`grade`, `sub_grade` and `int_rate` are produced by Lending Club's own risk model. They stay in the table **only as benchmarks** and will not be inputs to the scorecard. `fico_range_low` and `fico_range_high` are redundant with `bureau_score`, so only `bureau_score` will be used.

## 6. Charts

Saved in the `charts` folder:
- `01_grade.png` default rate by grade
- `02_score.png` default rate by bureau score band
- `03_dti.png` default rate by DTI decile
- `04_purpose.png` default rate by loan purpose
- `05_year.png` default rate by issue year
- `06_income.png` income distribution after capping
- `07_corr.png` correlation heatmap

## 7. Limitations

- US peer-to-peer lending data, not Indian lending data.
- Default is defined as Charged Off or Default, which is a simplified outcome and differs from the Indian 90-days-past-due standard.
- Findings are descriptive. They show patterns, not causes.
- Capping and median-filling are simple choices and could be tested for their effect on model results.

## 8. Next steps

1. Bin variables and compute Weight of Evidence and Information Value to choose scorecard inputs.
2. Fit a logistic regression on 2013-2014 loans and test it on 2015 loans.
3. Evaluate with AUC, Gini and KS, check stability with PSI, and compare the scorecard with Lending Club's grade.
4. Set a score cutoff and estimate expected loss.
