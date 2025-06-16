source "$SCRIPT_DIR/lib/colors.sh"
source "$SCRIPT_DIR/modules/cache.sh"
source "$SCRIPT_DIR/modules/utils.sh"

export ports_scanned=()
export vulnerabilities=()
export vulnerabilities_level=()

declare -g ports_scanned
declare -g vulnerabilities
declare -g vulnerabilities_level


function addVulnerability() {
    # $1 -> message
    # $2 -> level
    #   0 -> warning
    #   1 -> error
    #   2 -> severe vulnerability

    vulnerabilities+=("$1")
    vulnerabilities_level+=("$2")
}
