#!/bin/sh

set -ueo pipefail

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
SCRIPT_NAME="$(basename "$0")"; export SCRIPT_NAME

# Subpath in s3 bucket, end path will be s3://${AWS_BUCKET}${REMOTE_SUB_PATH}/
REMOTE_SUB_PATH=${REMOTE_SUB_PATH}
S3_TARGET_PATH="s3://${AWS_BUCKET}/${REMOTE_SUB_PATH}/"

TARGET_FILE=${TARGET_FILE:-/data/dump.sql}
TARGET_FILE_IS_DIR=0

usage(){
    cat << EOF
$SCRIPT_NAME - manage log rotate
Usage:
    ./$SCRIPT_NAME -h                   print this message and exit
    ./$SCRIPT_NAME rotateN <n>          keep N backups
    ./$SCRIPT_NAME rotateDate <date>    delete backups older than date (Not implemented)
EOF
}

errecho(){
    echo -e "\n$*" >&2
}

if [[ $# -lt 1 ]]; then
    errecho "Not enough params to call $SCRIPT_NAME !"
    usage >&2
    exit 1;
fi

rename_with_date() {
  FILE=$1
  # TODO(): add ability to change date format
  DATE_SUFFIX=$(date +"%d-%m-%Y_%H-%M-%S")
  NEW_FILENAME="${FILE%.*}_${DATE_SUFFIX}"

  EXTENSION=${FILE##*.}
  if [[ -n "$EXTENSION" ]]; then
    NEW_FILENAME="${NEW_FILENAME}.${EXTENSION}"
  fi
  mv $FILE $NEW_FILENAME
  echo "$NEW_FILENAME"
}

rotate_n() {
    set -ueo pipefail
    if [[ $# -lt 1 ]];then
        errecho "Not enough params to call $SCRIPT_NAME rotateN!"
        usage >&2
        exit 1;
    fi

    n=$1
    re='^[0-9]+$'
    if ! [[ $n =~ $re ]]; then
      echo "error: Not a number" >&2
      usage >&2
      exit 1;
    fi

    echo "[INFO] trying to rename file $TARGET_FILE"
    NEW_FILENAME=$(rename_with_date $TARGET_FILE)
    echo "[INFO] renamed file $TARGET_FILE to $NEW_FILENAME"

    if [[ -d $NEW_FILENAME ]]; then
      TARGET_FILE_IS_DIR=1
    fi

    echo "[INFO] copying to s3"

    CP_OPTS="--no-progress"
    if [[ $TARGET_FILE_IS_DIR -eq 1 ]]; then
      CP_OPTS+=" --recursive"
    fi

    aws s3 cp $CP_OPTS $NEW_FILENAME $S3_TARGET_PATH

    echo "[INFO] copied to s3"

    echo "[INFO] trying to delete old files"

    echo "[DEBUG] getting sorwted by time backups"
    OLD_IFS=${IFS}
    IFS="\n"
    all_backups=$(
      aws s3api list-objects --bucket ${AWS_BUCKET} --prefix "${REMOTE_SUB_PATH}/" --no-paginate --output json --delimiter "/" |\
      jq -r '.Contents | sort_by(.LastModified)[] | .Key'
    )
    RM_OPTS=""
    if [[ $TARGET_FILE_IS_DIR -eq 1 ]]; then
      RM_OPTS+=" --recursive"
    fi

    total_n=$(echo "$all_backups" | wc -l)
    echo "[DEBUG] $total_n in total backups"
    if [[ $total_n -le $n ]]; then
      echo "[DEBUG] $total_n <= $n, skip deleting backups"
    else
      n_to_delete=$(expr $total_n - $n)
      echo "[DEBUG] $total_n > $n, deleting $n_to_delete backups"

      echo $all_backups | head -n $n_to_delete | while read backup; do
        aws s3 rm $RM_OPTS "s3://${AWS_BUCKET}/$backup"
        echo "[DEBUG] deleted $backup"
      done

      echo "[INFO] deleted $n_to_delete files"
    fi
    IFS=$OLD_IFS
}


shift $((OPTIND-1))
subcommand="$1"; shift # Get subcommand and shift to next option
case "$subcommand" in
    -h | --help ) usage; exit 0 ;;
#    latest ) rotate_latest ;;
    rotateN )  rotate_n $@ ;;
    *) errecho "Unknow subcommand '$subcommand' !"; usage; exit 1; ;;
esac