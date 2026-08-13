g=open("ailed_high_difficulty_glm_res_question_id.txt","w")
with open("high_difficulty_glm_res.csv", "r") as f:
    for line in f:
        if line.startswith("id"):
            continue
        lst = line.rstrip().split(",")
        question_id = lst[0]
        score = float(lst[2])
        if score < 0.5:
            g.write(question_id + "\n")
            print(question_id)