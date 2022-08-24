#!/usr/bin/env bash
set -o xtrace
set -e

export OCI_CLI_AUTH=instance_principal
bucket_name=${bucket}
bmlt_filename_prefix=bmlt-
yap_filename_prefix=yap-
bmlt_filename=/tmp/"$${bmlt_filename_prefix}$(date +'%Y-%m-%d').sql.gz"
yap_filename=/tmp/"$${yap_filename_prefix}$(date +'%Y-%m-%d').sql.gz"


function cleanup() {
    rm -f $${bmlt_filename}
    rm -f $${yap_filename}
}

dump() {
    local db=$${1}
    local filename=$${2}
    mysqldump $${db} | gzip > $${filename}
}

upload() {
    local filename=$${1}
    oci os object put --bucket-name $${bucket_name} --file $${filename} --force
}

prune() {
    local prefix=$${1}
    local objects="$(oci os object list --bucket-name $${bucket_name} --prefix=$${prefix} | jq -r '.[] | sort_by(".name") | reverse | .[].name')"
    local i=0
    echo "$${objects}" | while read object; do
    if [[ "$${i}" -gt 3 ]]; then
        echo "deleting $${object}"
        oci os object delete --bucket-name $${bucket_name} --object-name=$${object} --force
    fi
    i=$((i+1))
    done
}

trap cleanup EXIT

dump bmlt $${bmlt_filename}
dump yap $${yap_filename}
upload $${bmlt_filename}
upload $${yap_filename}
prune $${bmlt_filename_prefix}
prune $${yap_filename_prefix}
