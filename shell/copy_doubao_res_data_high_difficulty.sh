## $1 question id
## $2 result dir index, eg 10,2,1

target_dir="/mnt/data/lengyang/github/PromptBio_Benchmark/${1}"
if [ ! -d ${target_dir} ];then
    mkdir -p  ${target_dir}
fi

model_res_dir="${target_dir}/results_doubao"
if [ ! -d ${model_res_dir} ];then
    mkdir -p  ${model_res_dir}
fi

task_dir="/mnt/data/lengyang/youjia_project/autoba/BABench/src/promptbio-bench/tasks"

data_dir="${task_dir}/${1}/data"
ref_answer="${task_dir}/${1}/ref_answer"
ref_script="${task_dir}/${1}/ref_script"
eval_file="${task_dir}/${1}/eval.json"
task_file="${task_dir}/${1}/task.json"


# if [ -d ${data_dir} ];then
#     echo "Copy ${data_dir} dir to ${target_dir}"
#     cp -r ${data_dir} ${target_dir}
# else
#     exit 1
# fi

########################################################################
## 1. Copy ref_answer, ref_script, eval.json, task.json to target_dir ##
########################################################################

if [ -d ${ref_answer} ];then
    echo "Copy ${ref_answer} dir to ${target_dir}"
    cp -r ${ref_answer} ${target_dir}
else
    echo "Error:${ref_answer} not exists "
    exit 1
fi

if [ -d ${ref_script} ];then
    echo "Copy ${ref_script} dir to ${target_dir}"
    cp -r ${ref_script} ${target_dir}
else
     echo "Error:${ref_script} dir not exists "
    exit 1
fi

# if [ -f ${eval_file} ];then
#     echo "Copy ${eval_file} dir to ${target_dir}"
#     cp  ${eval_file} ${target_dir}
# else
#      echo "Error:${eval_file} not exists "
#     exit 1
# fi

if [ -f ${task_file} ];then
    echo "Copy ${task_file} dir to ${target_dir}"
    cp ${task_file} ${target_dir}
else
    echo "Error:${task_file} not exists "
    exit 1
fi

date="20260623"
log_date="20260623-log"
#########################################################################
### 2. Copy model result answers, code and logs to target_dir/results_claude ##
#########################################################################

if [ -d ${task_dir}/${1}/result_${2} ];then
    if [ -d ${task_dir}/${1}/result_${2}/toolsgenie_${date}/work ];then
        echo "Copy  ${task_dir}/${1}/result_${2}/toolsgenie_${date}/work to ${model_res_dir}"
        cp -r ${task_dir}/${1}/result_${2}/toolsgenie_${date}/work ${model_res_dir}
    else
        echo "Error:${task_dir}/${1}/result_${2}/toolsgenie_${date}/work not exists "
        exit 1
    fi

    if [ -f ${task_dir}/${1}/result_${2}/toolsgenie_${log_date}/log.out ];then
        echo "Copy ${task_dir}/${1}/result_${2}/toolsgenie_${log_date}/log.out to ${model_res_dir}"
        cp -r ${task_dir}/${1}/result_${2}/toolsgenie_${log_date}/log.out ${model_res_dir}
    else
        echo "Error:${task_dir}/${1}/result_${2}/toolsgenie_${log_date}/log.out not exists "
        exit 1
    fi

    ls ${ref_answer}|while read id
    do
        if [ -f  ${task_dir}/${1}/result_${2}/toolsgenie_${date}/${id} ];then
            echo "Copy ${task_dir}/${1}/result_${2}/toolsgenie_${date}/${id} to ${model_res_dir}"
            cp ${task_dir}/${1}/result_${2}/toolsgenie_${date}/${id} ${model_res_dir}
        else
            echo "Error:${task_dir}/${1}/result_${2}/toolsgenie_${date}/${id} not exists "
            exit 1
        fi
    done
fi