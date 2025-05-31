tools_cache_folder="tools_cache"

function cache_folder_create() {
    if  [[ -f bascan_configs.sh ]]; then
        source ./bascan_configs.sh

        if [[ ! -f "$main_folder" ]]; then
            mkdir -p "$main_folder/$tools_cache_folder"
        fi

        return 0
    fi

    main_folder="bascan_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$main_folder/$tools_cache_folder"
    echo "main_folder=\"$main_folder\" # Folder of logs" > bascan_configs.sh
    echo "intensity=\"normal\"" >> bascan_configs.sh
    echo "multitrhead=false" >> bascan_configs.sh
    echo "fastmode=false" >> bascan_configs.sh
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
    # $2 -> new value

    cache_folder_create
    cp "bascan_configs.sh" "bascan_configs.sh.bak"
    sed -i "$1s/\([^=]*\)=\"[^\"]*\"/\1=\"$2\"/" "bascan_configs.sh"
}
