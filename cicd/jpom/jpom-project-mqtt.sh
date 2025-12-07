

#trigger_type=stop  
#trigger_result={"msgs":["running:3061094"],"pid":3061094,"statusMsg":"running:3061094","success":true}  
#trigger_project_name=th-core-server-pre  
#trigger_project_id=th-core-server-pre  

#trigger_result_str=$(echo "${trigger_result}" | sed 's/"/\\"/g')


if [[ -z "${trigger_project_id}" ]]; then
  echo "不存在结果" 2>&2
  exit 1
fi
if [[ "${trigger_type}" == "beforeStop" || "${trigger_type}" == "beforeRestart" || "${trigger_type}" == "fileChange" ]]; then
  echo "trigger_type 的值可以被忽视，脚本结束" 2>&2
  exit 0
fi


#{"msg_type":"text","content":{"text":'"${text}"'}}

postData='
项目变动通知
项目：'$trigger_project_name'
状态：'$trigger_type'
'

echo "$postData"

mosquitto_pub -h broker.emqx.io -t "test/th/jpom/hello" -m "$postData"





