#!/bin/bash

# test
#DCMD_SVR_USER=search
#DCMD_SVR_PATH=/letv/search
#DCMD_SVR_POOL=test_wanxiang_tdxy
###################################################################

PATH=$PATH:/usr/sbin:/sbin:/bin
export PATH
echo $PATH

# 确定部署目录
#WX_KEYWORD="wanxiang"
#GG_KEYWORD="guoguang"
KEYWORD="suggest"

if [[ $DCMD_SVR_POOL == *$KEYWORD* ]];then
    SVR_PATH="/letv/deploy/suggestion_test"
#elif [[ $DCMD_SVR_POOL == *$GG_KEYWORD* ]];then
#   SVR_PATH="/letv/deploy/data_access_proxy"
fi

prepare(){
echo  "Begin prepare........."
echo  "Action: $1"
echo  "service home: $2"
echo  "prepare enviroment:"

# 检查用户
id $DCMD_SVR_USER >/dev/null  
if [ $? -ne 0 ];then  
   useradd -d $DCMD_SVR_PATH $DCMD_SVR_USER  
   id $DCMD_SVR_USER
fi 
echo "$DCMD_SVR_USER user is ready."

# 检查部署目录
[[ -L $SVR_PATH/conf ]] && cd $SVR_PATH && mv conf conf.bak
[[ ! -d "$SVR_PATH" ]] && mkdir -p $SVR_PATH
[[ ! -d "$DCMD_SVR_PATH" ]] && mkdir -p $DCMD_SVR_PATH
chown -R $DCMD_SVR_USER.$DCMD_SVR_USER $DCMD_SVR_PATH  $SVR_PATH
id $DCMD_SVR_USER >/dev/null && [[ -d "$DCMD_SVR_PATH" ]] && [[ -d "$SVR_PATH" ]]
exit $?
}

start(){
echo  "Begin start........."
echo  "Action: $1"
echo  "service home: $2"
echo  "start enviroment:"
/bin/sh ${SVR_PATH}/sbin/start.sh start
exit $?
}

stop(){
echo  "Begin stop........."
echo  "Action: $1"
echo  "service home: $2"
echo  "stop enviroment:"
SERVICE_SBIN="${SVR_PATH}/sbin/start.sh"
if [ -f "${SERVICE_SBIN}" ];then
    /bin/sh $SERVICE_SBIN stop
else
    echo "don't init."
    exit 0
fi
exit $?
}

check(){
echo  "Begin check........."
echo  "Action: $1"
echo  "service home: $2"
echo  "check enviroment:"
ps -eaf |egrep  "`echo $SVR_PATH|awk -F '/' '{print $NF}'`/"  |grep -v grep
exit $?
}

install_app(){
echo  "Begin install........."
echo  "Action: $1"
echo  "service home: $2"
echo  "install type: $3"

LOG_DIR=$SVR_PATH/log
[[ ! -d "$LOG_DIR" ]] && /bin/mkdir -p $LOG_DIR
if [ $3 == "all" ];then
  echo  "new_pkg_path: $4"
  echo  "new_env_path: $5"
  SERVICE_PKG=$4
  SERVICE_ENV=$5
  #/bin/cp -arf $SERVICE_PKG/* $SVR_PATH/
  #chmod +x $SVR_PATH/bin/*
  #/bin/cp -arf $SERVICE_ENV/* $SVR_PATH/
  echo "----> copy complete!"
elif [ $3 == "pkg" ];then
  echo  "new_pkg_path: $4"
  #SERVICE_PKG=$4
  #/bin/cp -arf $SERVICE_PKG/* $SVR_PATH/
  #chmod +x $SVR_PATH/bin/*
  echo "----> copy complete!"
elif [ $3 == "env" ];then
  echo  "new_env_path: $4"
  #SERVICE_ENV=$4
  #/bin/cp -arf $SERVICE_ENV/* $SVR_PATH/
  #md5sum $SERVICE_HOME/conf/*
  echo "----> copy complete!"
else
  echo "invalid install type:$3"
fi
echo  "End install."
}

if [ $1 == "start" ]; then
  start $*
elif [ $1 == "stop" ]; then
  stop $*
elif [ $1 == "check" ]; then
  check $*
elif [ $1 == "install" ]; then
  install_app $*
elif [ $1 == "prepare" ]; then
  prepare $*
else
  echo "invalid action"
fi

