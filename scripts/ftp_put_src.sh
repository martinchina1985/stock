#!/bin/sh

## Fixed User Pass
FTP_USR=ftp
FTP_PWD=111

##########################################################
## Usage: $0 REMOTE_SERVER_IP put DirOrFile"
usage()
{
  echo -e "\nUsage:"
  echo -e "\t$0 REMOTE_SERVER_IP put DirOrFile"
}

## calc cdpath of ftp
# Format: $0 &result curModuleDir localBaseDir remoteBaseDir
calc_cdpath()
{
  ## Arguments Check
  if [ $# != 4 ] ; then
    echo "calc_cdpath(): outputStr curModuleDir localBaseDir remoteBaseDir"
    return 1
  fi
  
  ## Use sed ..
  local remotePath=`echo "$2" | sed "s#$3#$4#g"`
  local  __resultvar=$1
  eval $__resultvar="'${remotePath}'"
  return 0
}

### MAIN ENTRY ###
if [ $# != 3 ] ; then
  usage
  exit 1
fi

## echo "INVOKED: $0 $*"
## exit 0

## [work/src] is the relative path.
# LinuxSvr Commonly in ${HOME}/work/src
XLINUX_MODULE_BASE_DIR=${XLOCAL_SRC_BASE_DIR}
# RemotePC Commonly in ${FTP_ROOT}/work/src
REMOTE_MODULE_BASE_DIR=${REMOTE_SRC_BASE_DIR}

## Check Env x2
if [ "${XLINUX_MODULE_BASE_DIR}" == "" ] ; then
  XLINUX_MODULE_BASE_DIR="${HOME}/work/src"
  echo "WARN: Environment XLOCAL_SRC_BASE_DIR not found. Use default [${XLINUX_MODULE_BASE_DIR}]"
  # exit 1
fi

if [ "${REMOTE_MODULE_BASE_DIR}" == "" ] ; then
  REMOTE_MODULE_BASE_DIR="/work/src"
  echo "WARN: Environment REMOTE_SRC_BASE_DIR not found. Use default [${REMOTE_MODULE_BASE_DIR}]"
  # exit 1
fi

# alias fp="${ST_REL}/scripts/ftp_put_src.sh $REMOTE_SERVER put"
current_module_path=`pwd`
ftp_sync_cd_path=""
calc_cdpath ftp_sync_cd_path ${current_module_path} ${XLINUX_MODULE_BASE_DIR} ${REMOTE_MODULE_BASE_DIR}
f_ret=$?
if [ ${f_ret} != 0 ] ; then
  echo "Call calc_cdpath(): ${current_module_path} ${XLINUX_MODULE_BASE_DIR} ${REMOTE_MODULE_BASE_DIR} failed. (${f_ret})"
  exit 1
fi

## Usage: $0 REMOTE_SERVER_IP put DirOrFile"
FTP_SYNC_PATH=${ftp_sync_cd_path}
FTP_HOST=$1
PROMPT_DIRECTION="to"
## Command: get\put\mkdir
OP_CMD=$2
TARGET=$3
if [ "`file -b ${TARGET}`" == "directory" ] ; then
  echo "FTP: create Directory [${TARGET}] ${PROMPT_DIRECTION} ${FTP_HOST} at [${FTP_SYNC_PATH}] .."
  
  ## Final: ftp call 
ftp -i -n << END
    open ${FTP_HOST}
    user ${FTP_USR} ${FTP_PWD}
    cd ${FTP_SYNC_PATH}
    mkdir ${TARGET}
    bye
END

  ftp_ret=$?
  if [ ${ftp_ret} == 0 ] ; then
    echo "ok."
    exit 0
  else 
    echo "failed."
    exit 1
  fi
fi

## bin\asc
AS_SWITCH="asc"
## 1=Binary, 0=PlainText
is_binary=`isBinary ${TARGET} |awk '{if(NR==1)print $1}'`
if [ "${is_binary}" == "1" ] ; then
  AS_SWITCH="bin"
fi

echo "FTP: ${OP_CMD} ${AS_SWITCH} file [${TARGET}] ${PROMPT_DIRECTION} ${FTP_HOST} at [${FTP_SYNC_PATH}] .."
ftp -i -n << END
  open ${FTP_HOST}
  user ${FTP_USR} ${FTP_PWD}
  cd ${FTP_SYNC_PATH}
  ${AS_SWITCH}
  ${OP_CMD} ${TARGET}
  bye
END

ftp_ret=$?
if [ ${ftp_ret} == 0 ] ; then
  echo "ok."
  exit 0
else 
  echo "failed."
  exit 1
fi
