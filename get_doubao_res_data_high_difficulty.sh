bash ./shell/copy_doubao_res_data_high_difficulty.sh a-11-2 11
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-11-8 11
# ash ./shell/copy_doubao_res_data_high_difficulty.sh a-13-3 11 Error timeout
# bash ./shell/copy_doubao_res_data_high_difficulty.sh a-13-4 11 Error the task cannot be completed currently because the input file `/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks/a-13-4/result_11/toolsgenie_20260623/data/protein_sequence.csv` is only a Git LFS pointer, not the actual valid protein sequence data
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-13-5 11 #由于vincent 修改了题目的输出文件， 但代码跑在修改之前的的task.json 之上，导致豆包输出的结果虽然不符合提要要求的输出文件的格式，但是实际答案跟标准答案是一样的. 后面手动改成了正确的输出文件
# bash ./shell/copy_doubao_res_data_high_difficulty.sh a-14-1 11 Error timeout
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-14-2 11
# bash ./shell/copy_doubao_res_data_high_difficulty.sh a-15-2 11 Error timeout
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-15-7 11
#bash ./shell/copy_doubao_res_data_high_difficulty.sh a-15-8 11 Error timeout
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-15-9 11
#bash ./shell/copy_doubao_res_data_high_difficulty.sh a-3-5 11 Error, 结果文件没有输入到正确的文件夹中
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-3-6 11
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-4-6 11 # Error 修改了题目的输出文件， 但代码跑在修改之前的的task.json 之上，导致豆包输出的结果虽然不符合提要要求的输出文件的格式，后面手动改成正确的
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-4-8 11
bash ./shell/copy_doubao_res_data_high_difficulty.sh a-7-7 11
# bash ./shell/copy_doubao_res_data_high_difficulty.sh a-7-8 11 # timeout
#bash ./shell/copy_doubao_res_data_high_difficulty.sh a-9-1 11 # timeout
#bash ./shell/copy_doubao_res_data_high_difficulty.sh b-11-4 11 # timeout
#bash ./shell/copy_doubao_res_data_high_difficulty.sh b-8-10 11 # tomeout
#bash ./shell/copy_doubao_res_data_high_difficulty.sh b-9-4 11 # timeout