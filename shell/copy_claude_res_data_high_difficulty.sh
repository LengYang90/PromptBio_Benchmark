## $1 question id
## $2 a or b start

target_dir="/mnt/data/lengyang/github/PromptBio_Benchmark/${1}"
if [ ! -d ${target_dir} ];then
    mkdir -p  ${target_dir}
fi

model_res_dir="${target_dir}/results_claude"
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

#########################################################################
### 2. Copy model result answers, code and logs to target_dir/results_claude ##
#########################################################################

if [ -d ${task_dir}/${1}/result_10 ];then
    if [ -d ${task_dir}/${1}/result_10/toolsgenie_20260516/work ];then
        echo "Copy  ${task_dir}/${1}/result_10/toolsgenie_20260516/work to ${model_res_dir}"
        cp -r ${task_dir}/${1}/result_10/toolsgenie_20260516/work ${model_res_dir}
    else
        echo "Error:${task_dir}/${1}/result_10/toolsgenie_20260516/work not exists "
        exit 1
    fi

    if [ -f ${task_dir}/${1}/result_10/toolsgenie_20260516-log/log.out ];then
        echo "Copy ${task_dir}/${1}/result_10/toolsgenie_20260516-log/log.out to ${model_res_dir}"
        cp -r ${task_dir}/${1}/result_10/toolsgenie_20260516-log/log.out ${model_res_dir}
    else
        echo "Error:${task_dir}/${1}/result_10/toolsgenie_20260516-log/log.out not exists "
        exit 1
    fi

    ls ${ref_answer}|while read id
    do
        if [ -f  ${task_dir}/${1}/result_10/toolsgenie_20260516/${id} ];then
            echo "Copy ${task_dir}/${1}/result_10/toolsgenie_20260516/${id} to ${model_res_dir}"
            cp ${task_dir}/${1}/result_10/toolsgenie_20260516/${id} ${model_res_dir}
        else
            echo "Error:${task_dir}/${1}/result_10/toolsgenie_20260516/${id} not exists "
            exit 1
        fi
    done
elif [ -d ${task_dir}/${1}/result_1 ];then
   if [ -d ${task_dir}/${1}/result_1/toolsgenie_20260515/work ];then
        echo "Copy  ${task_dir}/${1}/result_1/toolsgenie_20260515/work to ${model_res_dir}"
        cp -r ${task_dir}/${1}/result_1/toolsgenie_20260515/work ${model_res_dir}
    else
        echo "Error:${task_dir}/${1}/result_1/toolsgenie_20260515/work not exists "
        exit 1
    fi

    if [ -f ${task_dir}/${1}/result_1/toolsgenie_20260515_log/log.out ];then
        echo "Copy ${task_dir}/${1}/result_1/toolsgenie_20260515_log/log.out to ${model_res_dir}"
        cp -r ${task_dir}/${1}/result_1/toolsgenie_20260515_log/log.out ${model_res_dir}
    else
        echo "Error:${task_dir}/${1}/result_1/toolsgenie_20260515_log/log.out not exists "
        exit 1
    fi

    ls ${ref_answer}|while read id
    do
        if [ -f ${task_dir}/${1}/result_1/toolsgenie_20260515/${id} ];then
            echo "Copy ${task_dir}/${1}/result_1/toolsgenie_20260515/${id} to ${model_res_dir}"
            cp ${task_dir}/${1}/result_1/toolsgenie_20260515/${id} ${model_res_dir}
        else
            echo "Error:${task_dir}/${1}/result_1/toolsgenie_20260515/${id} not exists "
            exit 1
        fi
    done
else
    echo "Error:Copy ${1} result answers failed"
    exit 1
fi