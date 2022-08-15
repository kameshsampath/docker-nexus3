#! /usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp "${SCRIPT_DIR}/nexus.properties" /nexus-data/etc/nexus.properties

set -uo pipefail

NEXUS_SCRIPTS=("anonymous-access" "update-admin-password" "my-docker-registry")
SCRIPT_FILE=${SCRIPT_FILE:-"${SCRIPT_DIR}/script.json"}
NEXUS_URL=${NEXUS_URL:-'http://localhost:8081'}
NEXUS_NS=${NEXUS_NS:-infra}
NEXUS_ADMIN_PASSWD=${NEXUS_ADMIN_PASSWD:-admin123}
ANONYMOUS_ACCESS=${ANONYMOUS_ACCESS:-false}

function wait_for_nexus() {
  res_code=$(curl --silent --fail --output /dev/null -w '%{http_code}' "${NEXUS_URL}")

  until [ "$res_code" -ne 000 ] &&  [ "$res_code" -lt 400 ];
  do
    sleep 5
    res_code=$(curl --silent --fail --output /dev/null -w '%{http_code}' "${NEXUS_URL}")
  done

  printf "\n Nexus Ready\n"
}

function check_if_script_exists(){
  local http_code
  http_code="$(curl -s -o /dev/null -I -w '%{http_code}' -X GET -u admin:$1 $NEXUS_URL/service/rest/v1/script/$2)"
  echo "$http_code"
}

function loadScripts(){
  local admin_pwd
  if [ -f  /nexus-data/admin.password ];
  then
    admin_pwd=$(cat /nexus-data/admin.password)
  else
    admin_pwd="${NEXUS_ADMIN_PASSWD}"
  fi

  for s in "${NEXUS_SCRIPTS[@]}"
  do 
    local script_json_file
    script_json_file=""${SCRIPT_DIR}/$s.json""
    local http_code
    http_code="$(check_if_script_exists $admin_pwd $s)"
    echo "$http_code"

    if [ "200" != "${http_code}" ];
    then 
      echo "Creating $s script"
      curl -v -X POST --header "Content-Type: application/json" \
        -u "admin:$admin_pwd" \
        -d@"$script_json_file" \
        "$NEXUS_URL/service/rest/v1/script"
    else
      echo "Updating $s script"
      curl -v -X PUT --header "Content-Type: application/json" \
        -u "admin:$admin_pwd" \
        -d@"$script_json_file" \
        "$NEXUS_URL/service/rest/v1/script/$s"
    fi
  done
}

function run_script(){
 local http_code
 http_code="$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: text/plain' -u admin:$1 $NEXUS_URL/service/rest/v1/script/$2/run -d $3)"
 echo "$http_code"
}

function update_admin_password(){
  if [ -f /nexus-data/admin.password ];
  then
    local admin_pwd
    admin_pwd=$(cat /nexus-data/admin.password)
    printf "\nUpdating the password\n"
    if [ "200" == "$(run_script $admin_pwd 'update-admin-password' $NEXUS_ADMIN_PASSWD)" ];
    then
      printf "\n Password updated successfully \n"
      rm -f /nexus-data/admin.password
    else
      printf "\n Password updated failed \n"
    fi
  else
    printf "\n Skipping Password reset\n"
  fi
}

## Enable/Disable Anonymous Access
function set_anonymous_access() {
  local admin_pwd
  if [ -f  /nexus-data/admin.password ];
  then
    admin_pwd=$(cat /nexus-data/admin.password)
  else
    admin_pwd="${NEXUS_ADMIN_PASSWD}"
  fi

  if [ "200" == "$(run_script "$admin_pwd" 'anonymous-access' "${ANONYMOUS_ACCESS}")" ];
    then
      printf "\n Updated anonymous access \n"
    else
      printf "\n Anonymous access update failed \n"
  fi
}

function create_docker_registry() {
  local admin_pwd
  if [ -f  /nexus-data/admin.password ];
  then
    admin_pwd=$(cat /nexus-data/admin.password)
  else
    admin_pwd="${NEXUS_ADMIN_PASSWD}"
  fi

  if [ "200" == "$(run_script "$admin_pwd" 'my-docker-registry' "@${SCRIPT_DIR}/my-docker-registry-params.json")" ];
    then
      printf "\n Added default private docker registry \n"
    else
      printf "\n Adding private docker registry failed \n"
  fi
}


wait_for_nexus
loadScripts

# enable exit on error
set -e 

update_admin_password
set_anonymous_access
create_docker_registry

exit 0