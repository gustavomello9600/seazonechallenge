# Seazone Challenge
Seazone tecnical challenge proposed for a Junior Data Scientist position

## Overview
To see the answers to the challenge, and a brief discussion of methods applied and problems solved, open the Report.pdf file on the repository root.

## Directory Structure
```
$ tree
│   README.md
│   Report.pdf
│   seazonechallenge.Rproj
│   seazone_challenge.pdf
│
├───data
│   ├───input
│   │       daily_revenue-challenge.csv
│   │       listings-challenge.csv
│   │
│   └───output
│           daily_revenue_listings.csv
│
└───scripts
        ChallengeAnswers.pdf
        ChallengeAnswers.Rmd
        ExploratoryDataAnalysis.pdf
        ExploratoryDataAnalysis.Rmd
        Modeling_Demand.pdf
        Modeling_Demand.Rmd
        Modeling_Revenue.pdf
        Modeling_Revenue.Rmd
```

* The data folder contains two subdirectories: input and output. Input folder contains the original data sent by Seazone. Output folder contains transformed data produced during the analysis process.
* The scripts folder contains R Markdown files describing, with both code and text, all the analysis process. It also contains PDF versions of the same files that displays the output of each code chunk.

## Reproducibility
To reproduce the analysis, do the following steps:

### Install Requirements
#### R packages
* tidyverse
* lubridate
* tsibble
* fable
* feasts
* xgboost
* fastDummies
* bizdays
* ggdark
* urca

Optional (for generating interactive plots):
* plotly

### Run Scripts
Run the R code from each file in the following order:
1. ExploratoryDataAnalysis.Rmd
2. Modeling_Revenue.Rmd
3. Modeling_Demand.Rmd
4. ChallengeAnswers.Rmd

## Bibliography
CHEN, Tianqi; GUESTRIN, Carlos. **Xgboost: A scalable tree boosting system**. In: Proceedings of the 22nd acm sigkdd international conference on knowledge discovery and data mining. 2016. p. 785-794.

FIORI, Anna Maria; FORONI, Ilaria. Prediction accuracy for reservation-based forecasting methods applied in revenue management. **International Journal of Hospitality Management**, v. 84, p. 102332, 2020.

GUIZZARDI, Andrea; PONS, Flavio Maria Emanuele; RANIERI, Ercolino. Advance booking and hotel price variability online: Any opportunity for business customers?. **International Journal of Hospitality Management**, v. 64, p. 85-93, 2017.

HASTIE, Trevor et al. **The elements of statistical learning: data mining, inference, and prediction**. New York: springer, 2009.

HYNDMAN, Rob J.; ATHANASOPOULOS, George. **Forecasting: principles and practice**. OTexts, 2018.

LAZZERI, Francesca. **Machine learning for time series forecasting with Python**. John Wiley & Sons, 2020.

YOUNG, Peter C.; PEDREGAL, Diego J.; TYCH, Wlodek. Dynamic harmonic regression. **Journal of forecasting**, v. 18, n. 6, p. 369-394, 1999.



