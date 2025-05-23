tools_cache_folder="tools_cache"

function cache_folder_create() {
    if  [[ ! -f bascan_configs.sh ]]; then
        main_folder="bascan-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$main_folder/$tools_cache_folder"
        echo "main_folder=\"$main_folder\"" > bascan_configs.sh
    fi
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

function cache_tools_file_getPath() {
    # $1 -> folder name
    # $2 -> file name

    if [[ -d "$main_folder/$tools_cache_folder/$1" && -f "$main_folder/$tools_cache_folder/$1/$2" ]]; then
        echo "$main_folder/$tools_cache_folder/$1/$2"
    fi
}
