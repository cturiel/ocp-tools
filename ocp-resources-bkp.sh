#!/bin/bash
# Author: Carlos Turiel
# Date 2024-02-02


OC_BIN="/usr/local/bin/oc"
CLUSTERNAME=$(${OC_BIN} whoami --show-server | sed -E 's|https?://||;s|:[0-9]+/?$||;s|/.*$||')
BACKUP_PATH="/tmp/backups_OCP/${CLUSTERNAME}/$(date +%Y%m%d-%H%M)"
LOG_FILE="${BACKUP_PATH}/backup_ocp_resources.log"
BACKUP_PATH_GLOBAL=${BACKUP_PATH}/globals
BACKUP_PATH_NS_ALL=${BACKUP_PATH}/namespaces
BACKUP_PATH_NS_INFRA=${BACKUP_PATH}/namespaces-infra

# Global OCP resources to backup.
RESOURCES_GLOBAL="Namespace RBACDefinition"
# Namespaced OCP resources to backup in all namespaces.
RESOURCES_NS_ALL="rolebindings serviceaccount"
# Namespaced OCP resources to backup in Infra namespaces.
RESOURCES_NS_INFRA="rolebindings serviceaccount ConfigMap Secret"

# NS_ALL="test-carlosts"
NS_ALL=$(${OC_BIN} get ns -o custom-columns=name:.metadata.name --sort-by=.metadata.name --no-headers)
NS_INFRA="openshift-config openshift-ingress openshift-marketplace"

# Exit when CTRL+C.
trap "{ echo 'Terminated with Ctrl+C'; exit 255; }" SIGINT

# Function to show logs in stdout and save them in a file.
echolog(){
  log_date="$(date +'[%F %T %Z]')"

  if [ $# -eq 0 ]; then
    cat - | while read -r message; do
      echo "$log_date - $message" | tee -a $LOG_FILE
    done
  else
    echo -e "$log_date - $*" | tee -a $LOG_FILE
  fi
}

echostatuslog(){
  log_date="$(date +'[%F %T %Z]')"
  msg="$log_date - ${1}"
  let col=90+${#log_date}-${#msg}
  [ "$2" -eq "0" ] && status="[Done]" || status="[Failed]"

  echo -n ${msg} | tee -a $LOG_FILE
  printf "%${col}s\n" "$status" | tee -a $LOG_FILE
  echo | tee -a $LOG_FILE
}

# Backup resources in the namespace
backup_ns_resources(){
  local namespaces=$1
  local backup_path=$2
  local resources=$3

  mkdir -p ${backup_path}
  
  for ns in ${namespaces}; do

    echolog "========================================================================================"
    echolog "Starting resources backup in the ${ns} namespace..."
    echolog "========================================================================================\n"

    backup_path_ns=${backup_path}/${ns}
    mkdir -p ${backup_path_ns}

    echolog "-> Getting all resources yaml..."
    ${OC_BIN} -n ${ns} get all -o yaml > ${backup_path_ns}/ns-all.yml 2>/dev/null
    echostatuslog "...Getting all resources yaml backup" "$?"

    for resource in ${resources}; do
      echolog "-> Getting ${resource} resource yaml..."
      ${OC_BIN} -n ${ns} get ${resource} -o yaml > ${backup_path_ns}/${resource}.yml 2>/dev/null
      echostatuslog "...${resource} resource yaml backup" "$?"

      for resource_name in $(${OC_BIN} -n ${ns} get ${resource} --no-headers | awk '{print $1}'); do
        mkdir -p ${backup_path_ns}/${resource}
        ${OC_BIN} -n ${ns} get ${resource} ${resource_name} -o yaml > ${backup_path_ns}/${resource}/${resource_name}.yml 2>/dev/null
      done
    done
    echolog "${ns} resources backup Done!.\n\n"
  done
}

mkdir -p ${BACKUP_PATH}

# --------------------------------------------------------------------------------
# Global resources backup
# --------------------------------------------------------------------------------
echolog "\n"
echolog "========================================================================================"
echolog " Starting Global resources backup..."
echolog "========================================================================================\n"

mkdir -p ${BACKUP_PATH_GLOBAL}

for RESOURCE in $RESOURCES_GLOBAL; do
  echolog "-> Getting ${RESOURCE} manifiest yaml..."
  ${OC_BIN} get ${RESOURCE} -o yaml > ${BACKUP_PATH_GLOBAL}/${RESOURCE}.yml 2>/dev/null
  echostatuslog "...${RESOURCE} manifiest yaml backup" "$?"

  for RESOURCE2 in $(${OC_BIN} get ${RESOURCE} --no-headers | awk '{print $1}'); do
    mkdir -p ${BACKUP_PATH_GLOBAL}/${RESOURCE}
    ${OC_BIN} get ${RESOURCE} ${RESOURCE2} -o yaml > ${BACKUP_PATH_GLOBAL}/${RESOURCE}/${RESOURCE2}.yml 2>/dev/null
  done
done

echolog "Global resources backup Done!.\n\n"


# --------------------------------------------------------------------------------
# Namespaced resources backup 
# --------------------------------------------------------------------------------
backup_ns_resources "${NS_ALL}" "${BACKUP_PATH_NS_ALL}" "${RESOURCES_NS_ALL}"

# --------------------------------------------------------------------------------
# Infra namespaced resources backup
# --------------------------------------------------------------------------------
backup_ns_resources "${NS_INFRA}" "${BACKUP_PATH_NS_INFRA}" "${RESOURCES_NS_INFRA}"


echolog "----------------------------------------------------------------------------------------\n"
echolog "OCP resources backup finished!!.\n\n"
exit 0
