## $1 question id
## $2 a or b start

target_dir="/mnt/data/lengyang/github/PromptBio_Benchmark/${1}"
if [ ! -d ${target_dir} ];then
    mkdir -p  ${target_dir}
fi

model_res_dir="${target_dir}/results_glm"
if [ ! -d ${model_res_dir} ];then
    mkdir -p  ${model_res_dir}
fi

data_dir="/mnt/data/lengyang/youjia_project/autoba/test_babench/tasks/${1}/data"
ref_answer="/mnt/data/lengyang/youjia_project/autoba/test_babench/tasks/${1}/ref_answer"
ref_script="/mnt/data/lengyang/youjia_project/autoba/test_babench/tasks/${1}/ref_script"
eval_file="/mnt/data/lengyang/youjia_project/autoba/test_babench/tasks/${1}/eval.json"
task_file="/mnt/data/lengyang/youjia_project/autoba/test_babench/tasks/${1}/task.json"


# if [ -d ${data_dir} ];then
#     echo "Copy ${data_dir} dir to ${target_dir}"
#     cp -r ${data_dir} ${target_dir}
# else
#     exit 1
# fi

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

if [ -f ${eval_file} ];then
    echo "Copy ${eval_file} dir to ${target_dir}"
    cp  ${eval_file} ${target_dir}
else
     echo "Error:${eval_file} not exists "
    exit 1
fi

if [ -f ${task_file} ];then
    echo "Copy ${task_file} dir to ${target_dir}"
    cp ${task_file} ${target_dir}
else
    echo "Error:${task_file} not exists "
    exit 1
fi
case "$2" in
    a)
        res="result_714"
        date="0714"
        task_dir="/mnt/data/lengyang/youjia_project/autoba/test_babench/tasks2"
        ;;
    b)
        res="result_79"
        date="0709"
        task_dir="/mnt/data/lengyang/youjia_project/autoba/test_babench/tasks"
        ;;
    *)
        echo "Error: parameter \$2 must be a or b"
        exit 1
        ;;
esac

glm_result_dir="${task_dir}/${1}/${res}/toolsgenie_2026${date}"
ls ${ref_answer}|while read id
do
    echo $id
    glm_answer_file="${glm_result_dir}/${id}"
    if [ -f ${glm_answer_file} ];then
        echo "Copy ${glm_answer_file} to ${model_res_dir}"
        cp ${glm_answer_file} ${model_res_dir}
    else
        echo "Error:${glm_answer_file} not exists "
        exit 1
    fi
done

if [ -d ${glm_result_dir}/work ];then
    echo "Copy ${glm_result_dir}/work to ${model_res_dir}"
    cp -r ${glm_result_dir}/work ${model_res_dir}
else
    echo "Error:${glm_result_dir}/work not exists "
    exit 1
fi

glm_result_log="${task_dir}/${1}/${res}/toolsgenie_2026${date}-log"
if [ -f ${glm_result_log}/log.out ];then
    echo "Copy ${glm_result_log}/log.out to ${model_res_dir}"
    cp -r ${glm_result_log}/log.out ${model_res_dir}
else
    echo "Error:${glm_result_log}/log.out not exists "
    exit 1
fi

