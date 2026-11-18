# Policy Report: Score Cutoff and Expected Loss (2015 out-of-time loans)

Notebook: `05_cutoff_policy.ipynb` | Input: `lc_scored.parquet` | Evaluated on 283,025 loans issued in 2015 (default rate 14.89%)

## 1. Approach

- **Policy form:** approve an applicant if the scorecard score is at or above a cutoff.
- **Evidence set:** only the 2015 loans, which the model never saw, so results show how a policy would have performed on new applicants.
- **Loss assumption:** loss given default (LGD) is not measured in this data, because recovery fields were deliberately excluded to avoid leakage. LGD is assumed at 65% of original principal and tested at 50% and 85%.
- **Economics:** interest income is calculated from each loan's rate with the standard amortisation formula (36 months). Only loans that repay earn interest. A defaulted loan loses LGD x principal.

## 2. Cutoff trade-off

| Cutoff | Approval rate | Default rate (approved) | Defaults avoided | Volume lost |
|---|---|---|---|---|
| None | 100% | 14.89% | 0% | 0% |
| 550 | 91.2% | 13.81% | 15.4% | 5.5% |
| 551.8 (decline band 1) | 88.6% | 13.53% | 19.5% | 7.3% |
| 557 | 79.3% | 12.60% | 32.9% | 14.3% |
| 565 | 60.1% | 10.84% | 56.3% | 30.7% |
| 570 | 47.1% | 9.50% | 70.0% | 43.3% |

- **Result:** a higher cutoff lowers the default rate of approved loans and avoids more defaults, but turns away more volume.
- **So what:** the rejected group defaults at 25-30%, roughly double the portfolio average, so the score separates risk usefully.
- **Caveat:** the cutoff also turns away borrowers who would have repaid and paid interest, which the next sections price.

## 3. Expected loss and economics by band (LGD 65%)

| Band | Default | Avg rate | Predicted loss | Actual-implied loss | Interest income | Net |
|---|---|---|---|---|---|---|
| 1 (riskiest) | 25.50% | 14.46% | 15.71% | 17.44% | 17.13% | -0.32% |
| 2 | 21.27% | 13.23% | 12.55% | 14.67% | 16.65% | 1.98% |
| 3 | 18.71% | 12.58% | 10.94% | 12.95% | 16.40% | 3.46% |
| 4 | 17.04% | 12.08% | 9.71% | 12.01% | 16.04% | 4.02% |
| 5 | 15.70% | 11.61% | 8.66% | 11.15% | 15.74% | 4.59% |
| 6 | 13.86% | 11.14% | 7.72% | 9.68% | 15.51% | 5.84% |
| 7 | 11.64% | 10.57% | 6.79% | 8.12% | 15.19% | 7.07% |
| 8 | 10.16% | 9.88% | 5.81% | 7.03% | 14.40% | 7.37% |
| 9 | 8.02% | 8.92% | 4.64% | 5.50% | 13.30% | 7.80% |
| 10 (safest) | 4.58% | 7.56% | 3.01% | 3.26% | 11.69% | 8.43% |

(All figures are percentages of each band's exposure.)

- **Result:** whole portfolio, predicted loss is 7.88% against 9.41% implied by actual defaults, and the net result is 5.51% of exposure. Net result rises steadily with score, and band 1 is the only band that is negative.
- **So what:** the scorecard prices risk correctly in direction, but the model under-predicts loss by about 1.5 points, consistent with the 2015 default shift found in the calibration check.
- **Caveat:** loss is applied to original principal, although borrowers who default usually repay part of the loan first. This overstates loss, so it is tested across LGD values below.

## 4. Does a cutoff pay? Sensitivity to LGD

Change in net result (interest minus loss, millions) versus approving everyone:

| Cutoff | LGD 50% | LGD 65% | LGD 85% |
|---|---|---|---|
| 540 | -0.6 | +0.3 | +1.6 |
| 550 | -7.0 | +1.2 | +12.0 |
| 551.8 (decline band 1) | -9.8 | +0.8 | +15.0 |
| 557 | -23.6 | -4.3 | +21.5 |
| 560 | -35.9 | -10.4 | +23.5 |
| 565 | -62.4 | -25.8 | +23.0 |
| 570 | -95.4 | -47.1 | +17.3 |

- **Result:** the financial value of a cutoff depends heavily on loss severity. With low LGD, declining anyone reduces profit, because interest from borrowers who would have repaid outweighs avoided losses. With high LGD, stricter cutoffs pay, peaking around 560-565.
- **So what:** a cutoff is a risk-appetite decision, not a single mathematical optimum. Declining band 1 is the most robust choice, with a modest downside when LGD is low and a clear gain when it is high.
- **Caveat:** the analysis excludes funding cost, servicing cost, prepayment, and recoveries. Including funding and servicing costs would make stricter cutoffs look better.

## 5. Recommended policy

| Tier | Bands | Share of loans | Default | Avg rate | Net (% of exposure, LGD 65%) | Action |
|---|---|---|---|---|---|---|
| 1 | 1 (score below about 552) | 11.4% | 25.50% | 14.46% | -0.32% | Decline |
| 2 | 2-3 | 20.4% | 20.00% | 12.91% | 2.74% | Approve with review or higher price |
| 3 | 4-10 | 68.2% | 11.59% | 10.26% | 6.65% | Approve |

**Effect of declining band 1 on 2015 loans:**
- Approval rate 88.6%.
- Default rate of approved loans falls from 14.89% to 13.53%.
- 19.5% of all defaults are avoided.
- 7.3% of exposure is turned away.
- Net result changes by -9.8M, +0.8M and +15.0M at LGD 50%, 65% and 85%.

**Recommendation:** decline applicants scoring below about 552, send bands 2-3 to review or price them higher, and approve the rest. Revisit the cutoff once recovery data is available and the model is recalibrated.

## 6. Limitations

- LGD is an assumption (65%, tested 50-85%), not measured.
- No funding cost, servicing cost, acquisition cost, prepayment or recovery timing.
- Interest and loss are simplified lifetime figures, not a full cash-flow model.
- One year (2015) of out-of-time evidence, and the model under-predicted 2015 default.
- US peer-to-peer lending data, not Indian lending data. The method transfers, the numbers do not.
