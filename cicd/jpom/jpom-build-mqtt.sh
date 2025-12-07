
#trigger_build_source_file=/home/data/tool/jpom-server/data/build/4294b69d16de412db7abf07b7655875a/source  
#trigger_build_number_id=3  
#trigger_trigger_build_type=0  
#trigger_type=finish  
#trigger_workspace_id=DEFAULT  
#trigger_build_result_dir_file=dist  
#trigger_build_result_file=/home/data/tool/jpom-server/data/build/4294b69d16de412db7abf07b7655875a/history/#3/result/dist  
#trigger_cluster_info_id=4ea40754a987419abf30c9770650c769  
#trigger_build_name=th-core-web-test  
#trigger_trigger_time=1764235284021  
#trigger_trigger_user=dev  
#trigger_build_id=4294b69d16de412db7abf07b7655875a  
#trigger_release_method=2  
#trigger_workspace_name=默认  



if [[ -z "${trigger_build_name}" ]]; then
  echo "不存在结果" 2>&2
  exit 1
fi
if [[ "${trigger_type}" == "pull" || "${trigger_type}" == "executeCommand" || "${trigger_type}" == "packageFile" || "${trigger_type}" == "release" || "${trigger_type}" == "finish" || "${trigger_type}" == "done" ]]; then
  echo "trigger_type 的值可以被忽视，脚本结束" 2>&2
  exit 0
fi


postData='
项目构建通知
构建项目：'$trigger_build_name'
构建ID：'$trigger_build_number_id'
构建状态：'$trigger_type'
'

echo "$postData"


mosquitto_pub -h broker.emqx.io -t "test/th/jpom/hello" -m "$postData"



