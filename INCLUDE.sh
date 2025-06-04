source ././lib/colors.sh
source ././modules/cache.sh
source ././modules/utils.sh

export HOST=$1
export ports_scanned=()
export vulnerabilities=()
export vulnerabilities_level=()

declare -g ports_scanned
declare -g vulnerabilities
declare -g vulnerabilities_level
declare -g HOST

function addVulnerability() {
    # $1 -> message
    # $2 -> level
    #   0 -> warning
    #   1 -> error
    #   2 -> severe vulnerability

    vulnerabilities+=("$1")
    vulnerabilities_level+=("$2")
}
