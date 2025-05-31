source ././lib/colors.sh
source ././modules/cache.sh
source ././modules/utils.sh

export HOST=$1
export ports_scanned=()

declare -g ports_scanned
declare -g HOST
