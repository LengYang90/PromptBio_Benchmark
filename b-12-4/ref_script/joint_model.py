import os
import pandas as pd
from lifelines import CoxPHFitter

task_dir = os.path.dirname(os.path.dirname(__file__))

# -----------------------------
# Step 1: Load data
# -----------------------------
surv_df = pd.read_csv(os.path.join(task_dir, "data", "survival_data.csv"))

# -----------------------------
# Step 2: Create ShrinkageGroup via median split
# -----------------------------
median_shrinkage = surv_df["EarlyShrinkage"].median()
surv_df["ShrinkageGroup"] = (surv_df["EarlyShrinkage"] > median_shrinkage).astype(int)

# -----------------------------
# Step 3: Fit Cox proportional hazards model
# -----------------------------
cph = CoxPHFitter()
cph.fit(surv_df[["SurvTime", "Event", "ShrinkageGroup"]],
        duration_col="SurvTime", event_col="Event")
cph.print_summary()

# -----------------------------
# Step 4: Predict survival probability at t=52 weeks
# -----------------------------
surv_df["PredictedSurvival"] = cph.predict_survival_function(surv_df, times=[52]).iloc[0, :].values
out_df = surv_df[["PatientID", "ShrinkageGroup", "PredictedSurvival"]]
out_df.to_csv(os.path.join(task_dir, "ref_answer", "survival_predictions.csv"), index=False)
print("Predicted survival probabilities saved.")
