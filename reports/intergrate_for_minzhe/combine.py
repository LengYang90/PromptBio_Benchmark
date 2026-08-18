import os
import pandas as pd
import numpy as np
script_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(os.path.dirname(script_dir))

glm_scores_path = os.path.join(script_dir, "failed_high_difficulty_glm_deepagent_evaluation_summary.csv")
claude_scores_path = os.path.join(script_dir, "failed_high_difficulty_claude_deepagent_evaluation_summary.csv")
doubao_scores_path = os.path.join(script_dir, "failed_high_difficulty_doubao_deepagent_evaluation_summary.csv")

glm_origin_res_path = os.path.join(parent_dir, "glm_res_summary.csv")
doubao_claude_origin_res_path = os.path.join(parent_dir, "all_evaluation_result_yj_merged.csv")

glm_df = pd.read_csv(glm_scores_path)
glm_scores_df = glm_df[["question_id", "score"]].rename(columns={"score": "evaluation_glm"})
claude_df = pd.read_csv(claude_scores_path)
claude_scores_df = claude_df[["question_id", "score"]].rename(columns={"score": "evaluation_claude"})
doubao_df = pd.read_csv(doubao_scores_path)
doubao_scores_df = doubao_df[["question_id", "score"]].rename(columns={"score": "evaluation_doubao"})

glm_rationale_df = glm_df[["question_id", "rationale"]].rename(columns={"rationale": "evaluation_glm_rationale"})
glm_rationale_df["evaluation_glm_rationale"] = (
    glm_rationale_df["evaluation_glm_rationale"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌") 
)
claude_rationale_df = claude_df[["question_id", "rationale"]].rename(columns={"rationale": "evaluation_claude_rationale"})
claude_rationale_df["evaluation_claude_rationale"] = (
    claude_rationale_df["evaluation_claude_rationale"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)
doubao_rationale_df = doubao_df[["question_id", "rationale"]].rename(columns={"rationale": "evaluation_doubao_rationale"})
doubao_rationale_df["evaluation_doubao_rationale"] = (
    doubao_rationale_df["evaluation_doubao_rationale"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)
rationale_df = pd.merge(glm_rationale_df, claude_rationale_df, on="question_id", how="outer")
rationale_df = pd.merge(rationale_df, doubao_rationale_df, on="question_id", how="outer")


glm_scores_df["evaluation_glm"] = (
    glm_scores_df["evaluation_glm"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)
claude_scores_df["evaluation_claude"] = (
    claude_scores_df["evaluation_claude"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)
doubao_scores_df["evaluation_doubao"] = (
    doubao_scores_df["evaluation_doubao"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)

evalution_scores_df = pd.merge(glm_scores_df, claude_scores_df, on="question_id", how="outer")
evalution_scores_df = pd.merge(evalution_scores_df, doubao_scores_df, on="question_id", how="outer")
# evalution_scores_df.columns = ["question_id", "evaluation_glm", "evaluation_claude", "evaluation_doubao"]


glm_origin_res_df = pd.read_csv(glm_origin_res_path)
doubao_claude_origin_res_df = pd.read_csv(doubao_claude_origin_res_path)

glm_origin_res_df = glm_origin_res_df[["id", "avg_similarity"]].rename(columns={"id": "question_id", "avg_similarity": "origin_glm"})
glm_origin_res_df["origin_glm"] = (
    glm_origin_res_df["origin_glm"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)


doubao_claude_origin_res_df = doubao_claude_origin_res_df[["id", "toolsgenie_doubao_avg_similarity", "toolsgenie_accuracy"]].rename(columns={"id": "question_id", "toolsgenie_doubao_avg_similarity": "origin_doubao", "toolsgenie_accuracy": "origin_claude"})

doubao_claude_origin_res_df["origin_doubao"] = (
    doubao_claude_origin_res_df["origin_doubao"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)
doubao_claude_origin_res_df["origin_claude"] = (
    doubao_claude_origin_res_df["origin_claude"]
    .replace(r"^\s*$", np.nan, regex=True)
    .fillna("❌")
)

origin_scores_df = pd.merge(glm_origin_res_df, doubao_claude_origin_res_df, on="question_id", how="outer")
origin_scores_df = origin_scores_df[["question_id", "origin_glm", "origin_claude", "origin_doubao"]]

evalution_scores_df.fillna(1, inplace=True)
combined_df = pd.merge( evalution_scores_df,origin_scores_df, on="question_id", how="left")
combined_df = pd.merge(combined_df, rationale_df, on="question_id", how="left")

high_difficulty_question_id= []
with open(f"{parent_dir}/id/high_difficulty_question_id.txt", "r") as f:
    for line in f:
        question_id = line.rstrip()
        high_difficulty_question_id.append(question_id)

print([id for id in combined_df["question_id"].values if id not in high_difficulty_question_id])

out_id = [id for id in high_difficulty_question_id if id not in combined_df["question_id"].values]
out_id_glm_score = glm_origin_res_df[glm_origin_res_df["question_id"].isin(out_id)][["question_id", "origin_glm"]]
out_id_claude_score = doubao_claude_origin_res_df[doubao_claude_origin_res_df["question_id"].isin(out_id)][["question_id", "origin_claude"]]
out_id_doubao_score = doubao_claude_origin_res_df[doubao_claude_origin_res_df["question_id"].isin(out_id)][["question_id", "origin_doubao"]]
out_id_score_df = pd.merge(out_id_glm_score, out_id_claude_score, on="question_id", how="outer")
out_id_score_df = pd.merge(out_id_score_df, out_id_doubao_score, on="question_id", how="outer")
out_id_score_df.fillna("❌", inplace=True)
out_id_score_df["evaluation_glm"] = ""
out_id_score_df["evaluation_claude"] = ""
out_id_score_df["evaluation_doubao"] = ""
out_id_score_df["evaluation_glm_rationale"] = ""
out_id_score_df["evaluation_claude_rationale"] = ""
out_id_score_df["evaluation_doubao_rationale"] = ""
out_id_score_df = out_id_score_df[["question_id", "evaluation_glm", "evaluation_claude", "evaluation_doubao", "origin_glm", "origin_claude", "origin_doubao", "evaluation_glm_rationale", "evaluation_claude_rationale", "evaluation_doubao_rationale"]]
combined_df = pd.concat([combined_df, out_id_score_df], ignore_index=True)

print([id for id in  high_difficulty_question_id if id not in combined_df["question_id"].values])

print(len(combined_df),len(high_difficulty_question_id))

combined_df.to_csv(os.path.join(script_dir, "failed_high_difficulty_deepagent_model_score_comparison.csv"), index=False)

