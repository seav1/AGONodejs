#!/bin/bash
# ===========================================设置相关参数=============================================
FLIE_PATH=/tmp/
if [ ! -d "${FLIE_PATH}" ]; then

  mkdir -pm 777 ${FLIE_PATH}

fi
if [ -s "./c.yml" ]; then
  source ./c.yml
fi
#设置app参数
export UUID=${UUID:-'fd80f56e-93f3-4c85-b2a8-c77216c509a7'}
export VPATH=${VPATH:-'vls'}
export CF_IP=${CF_IP:-'cdn.xn--b6gac.eu.org'}

#设置哪吒
NEZHA_SERVER=${NEZHA_SERVER:-'xxxxxxxxxx'}
NEZHA_KEY=${NEZHA_KEY:-'Uxxoavxxxxxxxi'}

#哪吒其他默认参数，无需更改
NEZHA_PORT=${NEZHA_PORT:-'443'}
NEZHA_TLS=${NEZHA_TLS:-'1'}

# 设置是否打印日志,no不打印 
RIZHI=${RIZHI:-'yes'}


# 设置x86_64-argo下载地址
 URL_CF=${URL_CF:-'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64'}

# 设置x86_64-NEZHA下载地址
 URL_NEZHA=${URL_NEZHA:-'https://github.com/seav1/ArgoNodejs/raw/main/nezha-amd'}

# 设置x86_64-bot下载地址
 URL_BOT=${URL_BOT:-'https://seav-xr.hf.space/kano-6'}

# 设置arm-argo下载地址
 URL_CF2=${URL_CF2:-'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64'}

# 设置arm-NEZHA下载地址
 URL_NEZHA2=${URL_NEZHA2:-'https://github.com/seav1/ArgoNodejs/raw/main/nezha-arm'}

# 设置arm-bot下载地址
 URL_BOT2=${URL_BOT2:-'https://seav-xr.hf.space/kano-6-arm'}


# 设置x86_64-app下载地址
 URL_APP=${URL_APP:-'https://github.com/seav1/ArgoNodejs/raw/main/main-amd'}
 # 设置arm-bot下载地址
 URL_APP2=${URL_APP2:-'https://github.com/seav1/ArgoNodejs/raw/main/main-arm'}

# ===========================================下载相关文件=============================================
# 清理旧文件
  [ -s ${FLIE_PATH}bot.js ] && [ -n "${BOT}" ] && rm -rf ${FLIE_PATH}bot.js
  sleep 1
  [ -s ${FLIE_PATH}nginx.js ] && [ -z "${TOK}" ] && rm -rf ${FLIE_PATH}nginx.js
  sleep 1
  [ -s ${FLIE_PATH}nezha.js ] && [ -z "${NEZHA_KEY}" ] && rm -rf ${FLIE_PATH}nezha.js
  if command -v curl &>/dev/null; then
        DOWNLOAD_CMD="curl -sL"
    # Check if wget is available
  elif command -v wget &>/dev/null; then
        DOWNLOAD_CMD="wget -qO-"
  else
        echo "Error: Neither curl nor wget found. Please install one of them."
        sleep 30
  fi
arch=$(uname -m)
if [[ $arch == "x86_64" ]]; then
# 下载argo

$DOWNLOAD_CMD ${URL_CF} > ${FLIE_PATH}nginx.js 

# 下载nezha
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]]; then
$DOWNLOAD_CMD ${URL_NEZHA} > ${FLIE_PATH}nezha.js 
fi
# 下载bot
if [[ -z "${BOT}" ]]; then
$DOWNLOAD_CMD ${URL_BOT} > ${FLIE_PATH}bot.js 
fi
# 下载app
if [[ -z "${APP}" ]]; then
$DOWNLOAD_CMD ${URL_APP} > ${FLIE_PATH}app.js 
fi
else
# 下载argo-arm

$DOWNLOAD_CMD ${URL_CF2} > ${FLIE_PATH}nginx.js 

# 下载nezha-arm
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]]; then
$DOWNLOAD_CMD ${URL_NEZHA2} > ${FLIE_PATH}nezha.js 
fi
# 下载bot-arm
if [[ -z "${BOT}" ]]; then
$DOWNLOAD_CMD ${URL_BOT2} > ${FLIE_PATH}bot.js 
fi
# 下载app-arm
if [[ -z "${APP}" ]]; then
$DOWNLOAD_CMD ${URL_APP2} > ${FLIE_PATH}app.js 
fi
fi
# ===========================================运行程序=============================================
# 运行nezha
run_nez() {
[ "${NEZHA_TLS}" = "1" ] && TLS='--tls'
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" && -s "${FLIE_PATH}nezha.js" ]]; then
chmod +x ${FLIE_PATH}nezha.js
nohup ${FLIE_PATH}nezha.js -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS} >/dev/null 2>&1 &
fi
}
# 运行bot
run_bot() {
if [[ -z "${BOT}"  && -s "${FLIE_PATH}bot.js" ]]; then
chmod +x ${FLIE_PATH}bot.js
nohup ${FLIE_PATH}bot.js >/dev/null 2>&1 &
fi
}
# 运行argo
run_arg() {
chmod +x ${FLIE_PATH}nginx.js
if [[ -n "${TOK}" ]]; then
TOK=$(echo ${TOK} | sed 's@cloudflared.exe service install ey@ey@g')
    if [[ "${TOK}" =~ TunnelSecret ]]; then
      echo "${TOK}" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' > ${FLIE_PATH}tunnel.json
      cat > {FLIE_PATH}tunnel.yml << EOF
tunnel: $(sed "s@.*TunnelID:\(.*\)}@\1@g" <<< "${TOK}")
credentials-file: {FLIE_PATH}tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:8002
EOF
      cat >> {FLIE_PATH}tunnel.yml << EOF
  - service: http_status:404
EOF
      nohup ${FLIE_PATH}nginx.js tunnel --edge-ip-version auto --config {FLIE_PATH}tunnel.yml run >/dev/null 2>&1 &
    elif [[ ${TOK} =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      nohup ${FLIE_PATH}nginx.js tunnel --edge-ip-version auto --protocol http2 run --token ${TOK} >/dev/null 2>&1 &
    fi
else
 nohup ${FLIE_PATH}nginx.js tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile ${FLIE_PATH}argo.log --loglevel info --url http://localhost:8002 2>/dev/null 2>&1 &
 sleep 5
 local LOCALHOST=$(ss -nltp | grep '"nginx.js"' | awk '{print $4}')
 export ARGO_DOMAIN=$(cat ${FLIE_PATH}argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
fi
}
# 运行JAR
run_jar() {
  if [[ -n "${JAR_FLIE2}" ]]; then
    if [ -s "./${JAR_FLIE2}" ] && [ -n "${JAR_FLIE}" ]; then
      mv -f ./${JAR_FLIE2} ${FLIE_PATH}${JAR_FLIE}
      ${JAR_SH} ${FLIE_PATH}${JAR_FLIE}${JAR_SH2}
    elif [ -s "./${JAR_FLIE2}" ] && [ -z "${JAR_FLIE}" ]; then
      ${JAR_SH} ./${JAR_FLIE2}${JAR_SH2}
    fi
  fi  
}
# 运行app
run_app() {
chmod +x ${FLIE_PATH}app.js
nohup ${FLIE_PATH}app.js >/dev/null 2>&1 &
}
run_nez
run_bot
run_arg
sleep 10
run_jar
run_app
# ===========================================显示系统信息=============================================

[ "$RIZHI" = "yes" ] && echo "--------- ---系统信息--------- ----"
[ "$RIZHI" = "yes" ] && cat /proc/version

# ===========================================显示IP位置=============================================
ipv4=$(curl -s4m6 api64.ipify.org -k)
iploacation=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=en-US -k | cut -f2 -d"," | cut -f4 -d '"'`
[ "$RIZHI" = "yes" ] && echo "***************************************************"
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "       IP : $ipv4, Location： $iploacation"
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "***************************************************"
if [[ -n "${SERVER_IP}" ]]; then
[ "$RIZHI" = "yes" ] && echo "               玩具鸡不要启动自带程序否则端口冲突，但不影响临时节点使用               "
[ "$RIZHI" = "yes" ] && echo "                         "
[ "$RIZHI" = "yes" ] && echo "               ${SERVER_IP}:${SERVER_PORT} 主页               "
[ "$RIZHI" = "yes" ] && echo "               ${SERVER_IP}:${SERVER_PORT}/${UUID} 节点信息               "
[ "$RIZHI" = "yes" ] && echo "               ${SERVER_IP}:${SERVER_PORT}/sub-${UUID} 订阅地址               "
[ "$RIZHI" = "yes" ] && echo "               ${SERVER_IP}:${SERVER_PORT}/info 系统信息               "
[ "$RIZHI" = "yes" ] && echo "               ${SERVER_IP}:${SERVER_PORT}/listen 监听端口               "
[ "$RIZHI" = "yes" ] && echo "***************************************************"

fi
[ "$RIZHI" = "yes" ] && echo "                         "
[ "$RIZHI" = "yes" ] && echo "                   vless节点信息                   "
[ "$RIZHI" = "yes" ] && echo "vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#Vless-argo"
[ "$RIZHI" = "yes" ] && echo "***************************************************"
[ "$RIZHI" = "yes" ] && echo "                         "

# ===========================================显示进程信息=============================================
if command -v ps -ef >/dev/null 2>&1; then
   fps='ps -ef'
elif command -v pgrep -lf >/dev/null 2>&1; then
   fps='pgrep -lf'
elif command -v ps aux >/dev/null 2>&1; then
   fps='ps aux'
elif command -v ss -nltp >/dev/null 2>&1; then
   fps='ss -nltp'
else
   fps='0'
fi
if [ "$fps" != '0' ]; then
num=$(${fps} |grep -v "grep" |wc -l)
[ $RIZHI == "yes" ] && echo "$num"
fi
# ===========================================运行进程守护程序=============================================

# 检测bot
function check_bot(){
  count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] &&  echo "----- 检测到bot未运行，重启应用...----- ."
  run_bot
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "bot is running......"
fi
}

# 检测nginx
function check_cf (){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] && echo "----- 检测到nginx未运行，重启应用...----- ."
   run_arg
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "nginx is running......"
fi
}
# 检测nezha
function check_nezha(){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] && echo "----- 检测到nezha未运行，重启应用...----- ."
  run_nez
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "nezha is running......" 
fi
}
# 检测app
function check_app(){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] && echo "----- 检测到app未运行，重启应用...----- ."
  run_app
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "app is running......" 
fi
}


# 循环调用检测进程
while true
do
if [ "$num" -ge  "4" ] && [ "$fps" != 'ss -nltp' ]; then
  [ -s ${FLIE_PATH}bot.js ] && [ -z "${BOT}" ] && check_bot bot.js
  sleep 10
  [ -s ${FLIE_PATH}nginx.js ] && check_cf nginx.js
  sleep 10
  [ -s ${FLIE_PATH}nezha.js ] && [ -n "${NEZHA_KEY}" ] && check_nezha nezha.js

[ "$RIZHI" = "yes" ] && echo "完成一轮检测，60秒后进入下一轮检测"
  sleep 60
elif [ "$num" -ge  "4" ] && [ "$fps" = 'ss -nltp' ]; then 
  [ -s ${FLIE_PATH}bot.js ] && [ -z "${BOT}" ] && check_bot bot.js
  sleep 10
  [ -s ${FLIE_PATH}nginx.js ] && check_cf nginx.js

[ "$RIZHI" = "yes" ] && echo "完成一轮检测，60秒后进入下一轮检测"
else
  sleep 6000
[ "$RIZHI" = "yes" ] && echo "app is running"
fi
  if [[ -n "${BAOHUO_URL}" ]]; then
   curl -s -m 5 https://${BAOHUO_URL} >/dev/null 2>&1 &
  fi  
done
