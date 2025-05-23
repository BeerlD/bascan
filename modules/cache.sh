tools_cache_folder="tools_cache"

function cache_folder_create() {
    if  [[ ! -f bascan_configs.sh ]]; then
        main_folder="bascan-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$main_folder/$tools_cache_folder"
        echo "main_folder=\"$main_folder\"" > bascan_configs.sh
    fi
}

