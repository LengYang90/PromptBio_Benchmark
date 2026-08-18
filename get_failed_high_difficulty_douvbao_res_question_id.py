g=open("./id/failed_high_difficulty_doubao_res_question_id.txt","w")

high_difficulty_question_id = list()
with open("./id/high_difficulty_question_id.txt", "r") as f:
    for line in f:
        question_id = line.rstrip()
        high_difficulty_question_id.append(question_id)

print(high_difficulty_question_id)
with open("all_evaluation_result_yj_merged.csv", "r") as f:
    for line in f:
        if line.startswith("id"):
            continue
        lst = line.rstrip().split(",")
        question_id = lst[0]
        if question_id not in high_difficulty_question_id:
            continue
        score = float(lst[16])
        if score < 0.5:
            print(question_id, score)
            g.write(question_id + "\n")