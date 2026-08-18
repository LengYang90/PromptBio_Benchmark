g=open("./id/failed_high_difficulty_glm_res_question_id2.txt","w")
high_difficulty_question_id = list()
with open("./id/high_difficulty_question_id.txt", "r") as f:
    for line in f:
        question_id = line.rstrip()
        high_difficulty_question_id.append(question_id)
with open("glm_res_summary.csv", "r") as f:
    for line in f:
        if line.startswith("id"):
            continue
        lst = line.rstrip().split(",")
        question_id = lst[0]
        if question_id not in high_difficulty_question_id:
            continue
        score = float(lst[2])
        if score < 0.5:
            g.write(question_id + "\n")
            print(question_id,score)