head -1 glm_res_summary.csv >high_difficulty_glm_res.csv
cat high_difficulty_question_id.txt|while read id
do
    grep $id glm_res_summary.csv >>high_difficulty_glm_res.csv
done