tools_cache_folder="tools_cache"

cache_folder_create() {
    tools_cache_folder="tools_cache"

    if [[ -f bascan_configs.sh ]]; then
        source ./bascan_configs.sh

        if [[ "$#" -eq 1 && "$1" == true ]]; then
            main_folder="bascan_$(date +%Y-%m-%d_%H:%M:%S)"
            mkdir -p "$main_folder/$tools_cache_folder"
            sed -i "s|^main_folder=.*|main_folder=\"$main_folder\" # Folder of logs|" bascan_configs.sh
        elif [[ ! -d "$main_folder" ]]; then
            mkdir -p "$main_folder/$tools_cache_folder"
        fi

        return 0
    fi

    main_folder="bascan_$(date +%Y-%m-%d_%H:%M:%S)"
    mkdir -p "$main_folder/$tools_cache_folder"

    cat > bascan_configs.sh <<EOF
main_folder="$main_folder" # Folder of logs
tools_cache_folder="$tools_cache_folder"
intensity="normal"
multitrhead=false
fastmode=false
new_cache_folder=false
EOF
}


function cache_tools_file_create() {
    # $1 -> folder name
    # $2 -> file name

    cache_folder_create
    source ./bascan_configs.sh

    cd "$main_folder/$tools_cache_folder"
    mkdir -p "$1"
    cd "$1"

    echo "" > "$2"
    cd ../../../
}

function cache_tools_file_create_without_folder() {
    # $1 -> file name

    cache_folder_create
    source ./bascan_configs.sh

    cd "$main_folder/$tools_cache_folder"
    echo "" > "$1"
    cd ../../
}

function cache_tools_file_getPath() {
    # $1 -> folder name
    # $2 -> file name

    source ./bascan_configs.sh

    if [[ -d "$main_folder/$tools_cache_folder/$1" && -f "$main_folder/$tools_cache_folder/$1/$2" ]]; then
        echo "$main_folder/$tools_cache_folder/$1/$2"
    elif [[ -f "$main_folder/$tools_cache_folder/$2" ]]; then
        echo "$main_folder/$tools_cache_folder/$2"
    fi
}

function cache_config_file_setValue() {
    # $1 -> line number
    # $2 -> new value (passar aspas se quiser)

    cache_folder_create
    cp "bascan_configs.sh" "bascan_configs.sh.bak"
    sed -i "$1s/\([^=]*\)=.*/\1=$2/" "bascan_configs.sh"
}
