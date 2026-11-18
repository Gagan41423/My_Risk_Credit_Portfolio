# Model Report: Lending Club Credit Scorecard (36-month loans, 2013-2015)

Notebook: `03_scorecard.ipynb` | Data: `lc_clean_v2.parquet` | Outputs: `lc_scored.parquet`, `scorecard_points.csv`, `iv_table.csv`

## 1. Approach

- **Model type:** Weight-of-Evidence (WOE) binning followed by logistic regression, the standard transparent scorecard method used by lenders.
- **Target:** `bad` = 1 for Charged Off or Default, 0 for Fully Paid.
- **Data split:**

| Set | Loans | Default rate |
|---|---|---|
| Train (2013-2014, 70%) | 184,093 | 13.19% |
| Validation (2013-2014, 30%) | 78,898 | 13.19% |
| Out-of-time test (2015) | 283,025 | 14.89% |

- **Why split by time:** the 2015 loans act as future loans the model has never seen, so the test is realistic. Bin edges and WOE values were calculated on the train set only.
- **Excluded inputs:** `grade`, `sub_grade` and `int_rate` come from Lending Club's own risk model, so they were kept out and used only as benchmarks. The FICO range columns were replaced by their average, `bureau_score`. No post-issuance fields (payments, recoveries) were ever loaded.

## 2. Variable selection

**Result:** 8 of 21 candidate variables had an Information Value (IV) of at least 0.02 and entered the model.

| Variable | IV | Strength |
|---|---|---|
| bureau_score | 0.134 | Medium |
| income | 0.092 | Weak |
| obligation_ratio (DTI) | 0.052 | Weak |
| home_ownership | 0.042 | Weak |
| mort_acc | 0.042 | Weak |
| credit_history_years | 0.024 | Weak |
| purpose | 0.021 | Weak |
| revol_bal | 0.020 | Weak |

- **Evidence:** the highest correlation between selected variables is 0.51 (`home_ownership` and `mort_acc`), below the 0.7 limit, so none was dropped. All 8 coefficients in the logistic regression are negative (from -0.11 to -0.91), as expected when WOE is higher for safer bins. No IV exceeds 0.5, so there is no sign of leakage.
- **So what:** the model is driven mainly by credit score, income and debt burden, which agrees with the EDA findings.
- **Caveat:** `enquiries_6m` (IV 0.0197) and `utilization` (0.0185) fell just under the cut-off. The 0.02 threshold is a convention, and including `enquiries_6m` is a reasonable alternative to test.

## 3. Model performance

| Set | AUC | Gini | KS |
|---|---|---|---|
| Train | 0.641 | 0.282 | 0.203 |
| Validation | 0.637 | 0.274 | 0.202 |
| OOT 2015 | 0.639 | 0.278 | 0.201 |

- **Result:** the scorecard ranks risk consistently across all three sets.
- **Evidence:** train, validation and OOT are nearly identical, so the model does not overfit and keeps its ranking power on later loans.
- **So what:** an AUC of about 0.64 is realistic for consumer credit when the lender's own grade is excluded. A value much higher (for example 0.75 or more) would have pointed to leakage.
- **Caveat:** the model is moderately predictive, not strong. It is useful for ranking and cutoffs, not for precise individual predictions.

## 4. Benchmarks

| Model or score (OOT 2015) | AUC |
|---|---|
| Scorecard (WOE logistic regression) | 0.639 |
| Gradient boosting on raw variables | 0.663 |
| Lending Club grade (A to G) | 0.668 |
| Lending Club `int_rate` | 0.678 |
| Bureau score alone | 0.601 |

- **Result:** the scorecard beats the bureau score alone by 0.038 AUC, so the other variables add real value. It gives up 0.024 AUC to a more complex model in exchange for full explainability.
- **So what:** a simple, explainable scorecard loses little accuracy, which is a reason banks prefer them.
- **Caveat:** Lending Club's own grade and rate perform better, because they used information not available here. This project does not beat them, and the report should say so.

## 5. Calibration and stability

| Decile (1 = lowest risk) | Predicted PD | Actual default | Gap (points) |
|---|---|---|---|
| 1 | 4.72% | 4.60% | -0.12 |
| 2 | 7.22% | 8.15% | 0.93 |
| 3 | 9.07% | 10.28% | 1.21 |
| 4 | 10.61% | 11.84% | 1.23 |
| 5 | 12.08% | 14.08% | 1.99 |
| 6 | 13.59% | 16.04% | 2.46 |
| 7 | 15.24% | 17.42% | 2.18 |
| 8 | 17.20% | 18.91% | 1.71 |
| 9 | 19.79% | 21.75% | 1.95 |
| 10 | 24.85% | 25.80% | 0.95 |

- **Result:** the ranking is right, but the model under-predicts default on 2015 loans. Average predicted PD is 13.44% against an actual 14.89%.
- **Evidence:** the gap reaches about 2.5 points in the middle deciles. The Population Stability Index (PSI) between train and OOT scores is 0.002, far below the 0.1 stability limit.
- **So what:** the *mix of scores* did not change, but the *default level* at each score rose. This matches the EDA finding that default rates rose inside most grades between 2013 and 2015. A lender would recalibrate the model regularly.
- **Caveat:** the data cannot say why defaults rose (borrower quality, economic conditions or lender behavior).

## 6. Score scale and bands

- **Scale:** 600 points at 20:1 good-to-bad odds, 20 points to double the odds (PDO = 20). Higher score means lower risk. Check values: odds 20:1 gives 600, 40:1 gives 620, 10:1 gives 580.
- **Observed range:** about 521 to 621 on OOT loans (median about 569). Scores sit below 600 because the portfolio's real odds (about 6:1) are lower than the 20:1 base. The scale can be shifted by changing the base odds or PDO.

| Band (1 = riskiest) | Score range | Train default | Validation default | OOT default |
|---|---|---|---|---|
| 1 | below 552 | 23.8% | 22.3% | 25.5% |
| 2 | 552 to 557 | 19.6% | 19.7% | 21.3% |
| 3 | 557 to 562 | 17.4% | 17.8% | 18.7% |
| 4 | 562 to 566 | 14.7% | 15.5% | 17.0% |
| 5 | 566 to 569 | 13.7% | 13.5% | 15.7% |
| 6 | 569 to 573 | 11.8% | 12.0% | 13.9% |
| 7 | 573 to 578 | 10.8% | 10.6% | 11.6% |
| 8 | 578 to 584 | 8.8% | 9.1% | 10.2% |
| 9 | 584 to 593 | 6.9% | 6.9% | 8.0% |
| 10 | 593 and above | 4.5% | 4.6% | 4.6% |

- **Result:** default falls steadily as the score rises, in every set.
- **So what:** the bottom bands (1 to 3) carry default rates of 19-26% and are the natural place for a cutoff, which the next phase analyzes.
- **Caveat:** OOT default rates exceed train rates in most bands, the same 2015 shift as in Section 5.

## 7. Scorecard table

`scorecard_points.csv` lists the points for every bin of every variable. A loan's score is the sum of its attribute points, and the notebook verifies this reproduces each model score (difference about 1e-13). This makes each decision traceable to specific inputs.

## 8. Limitations

- US peer-to-peer lending data, not Indian lending data. The method transfers, the coefficients do not.
- Default is defined as Charged Off or Default, which differs from the Indian 90-days-past-due standard.
- A simple model with 8 variables, no interaction effects, and no fairness testing yet.
- No recalibration for the 2015 default shift, and no recovery data, so loss estimates later will use an assumed LGD.
- Results are descriptive and predictive, not causal.

## 9. Next steps

1. Choose a score cutoff and compare approval rate against default rate.
2. Estimate expected loss (PD x LGD x exposure) by band, with a stated LGD assumption.
3. Write the policy recommendation and add the results to the Power BI dashboard and README.
