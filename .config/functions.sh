#!/usr/bin/env bash

. $DOCKER_LAMP_BASEDIR/.config/docker-lamp-completion.bash

usage() {
    warn "-- Help for the command:" "$(basename $0)" "$*" "--"
    echo
    [ ! -z "$1" ] && eval "usage_$1" && exit 0
    warn "Usage:"
    success "-> $(basename $0) <command> [<parameters>]"
    echo
    warn "For more details about the allowed parameters use:"
    success "-> $(basename $0) <command> --help"
    echo
    warn "Commands:"
    warn "start [<parameters>]"
    info "-> If 'start' is used without parameters, the server is started with the globally defined settings from the '.env' file."
    info "-> If parameters are set, these will override the global settings. The phpmyadmin and mailcatcher containers always start."
    echo
    warn "restart"
    info "-> Restarts the server with the same configuration as started before."
    echo
    warn "shutdown [<parameters>]"
    info "-> Shuts down the server completely deleting also all volumes created."
    info "-> If not other set, all databases will be saved before."
    echo
    warn "stop"
    info "-> Stops the server."
    info "-> However, unlike 'shutdown', the database volume is preserved and the databases are not saved before."
    info "-> Likewise, the files in the 'initDB' folder are ignored by the next start."
    echo
    warn "update-images"
    info "-> Downloads the newest images globally defined in the '.env' file, or set in the parameters."
    info "-> If parameters are set, these will override the global settings. The new images will be tagged all latest."
    echo
    warn "delete-obsolete-images"
    info "-> Deletes obsolete images remaining after updated images."
    echo
    warn "cli <CONTAINER-NAME> [<parameters>][ '<COMMAND-TO-PASS>']"
    info "-> Uses 'docker exec -it <CONTAINER-NAME>' to launch into the cli in the container, or to execute the passed command."
    info "-> Use single quotes ' to pass the command to the container to be executed in it."
    echo
    warn "save-db <DB-SERVER> [<parameters>]"
    info "-> Saves the databases of the given database server as sql files into 'initDB/<DB-SERVER>'."
    info "-> Without '-d', all databases are saved and a confirmation is asked."
    echo
    warn "restore-db <DB-SERVER> [<parameters>]"
    info "-> Restores the dumps from 'initDB/<DB-SERVER>' into the running database server."
    info "-> Without '-d', all dumps are restored and a confirmation is asked."
    exit 0
}

usage_start() {
    warn "Usage:"
    success "-> $(basename $0) start [<parameters>]"
    echo
    info "-> If 'start' is used without parameters, the server is started with the globally defined settings from the '.env' file."
    info "-> If parameters are set, these will override the global settings. The phpmyadmin and mailcatcher containers always start."
    echo
    echo
    warn "Parameters:"
    echo
    warn "-p, --php="
    info "-> Use the service names from the yaml file defined for the php versions."
    info "-> Put the value in quotes and separate multiple versions by space like 'php56 php73 php80'."
    echo
    warn "-H, --httpd="
    info "-> Use the service name from the yaml file defined for the httpd service like 'apache24'."
    echo
    warn "-d, --db="
    info "-> Use the service name from the yaml file defined for the database service like 'mariadb104' or 'mariadb105'."
    echo
    warn "-m, --map-80-443="
    info "-> Use the service name from the yaml file defined for the php version You want to map the default browser ports (80 and 443) for, like 'php74'."
    echo
    warn "--bind-on"
    info "-> If set, it will override the global configuration in '.env' to 'USE_BIND=1'"
    echo
    warn "--bind-off"
    info "-> If set, it will override the global configuration in '.env' to 'USE_BIND=0'"
    echo
    warn "--help"
    info "-> Show this help."
    echo
    echo
    info_b "Example:"
    success "-> $(basename $0) start --php='php74 php80' --httpd='apache24'"
    success "-> $(basename $0) start -p 'php74 php80' -H 'apache24'"
    info "-> Starts the server with php74 and php80, apache24, phpmyadmin, mailcatcher and the settings defined global in '.env' for db and bind."
    exit 0
}

usage_restart() {
    warn "Usage:"
    success "-> $(basename $0) restart"
    echo
    info "-> Restarts the server with the same configuration as started before."
    exit 0
}

usage_shutdown() {
    warn "Usage:"
    success "-> $(basename $0) shutdown [<parameters>]"
    echo
    info "-> Shuts down the server completely deleting also all volumes created."
    info "-> If not other set, all databases will be saved before."
    info_b "-> IMPORTANT: All existing files in 'initDB' will be overridden."
    echo
    echo
    warn "Parameters:"
    echo
    warn "-s, --skip-save-db"
    info "-> If this option is set, no databases and no archives are saved."
    echo
    warn "-a, --archive"
    info "-> A copy of all databases is additionally archived in the subfolder within 'initDB' specified with the '-b or --backup-folder=' parameter."
    info "-> If this parameter is not set, the databases are archived by default in a subfolder, with the current date as name, in this format 'yyyy-mm-dd'."
    info "-> If set, it will override the global configuration in '.env' to 'ARCHIVE_DATABASES=1'"
    echo
    warn "-b, --backup-folder="
    info "-> Set the subfolder within 'initDB', all databases will be archives into."
    echo
    echo
    info_b "Example:"
    success "-> $(basename $0) stop -a -b \"lt_\$(date +%Y-%m-%d)\""
    info "-> Saves all databases into 'initDB' and overwrites each of the existing ones and also archives a copy into 'initDB/lt_yyyy-mm-dd', then stops all containers and deletes all created volumes."
    echo
    success "-> $(basename $0) stop"
    info "-> Saves all databases into 'initDB' and overwrites each of the existing ones, then stops all containers and deletes all created volumes."
    exit 0
}

usage_stop() {
    warn "Usage: $(basename $0) stop"
    echo
    info "-> Stops the server."
    info "-> However, unlike 'shutdown', the database volume is preserved and the databases are not saved before."
    info "-> Likewise, the files in the 'initDB' folder are ignored by the next start."
    echo
    warn "Anyway, if you like to save (and archive) the databases,"
    warn "You need to use '$(basename $0) save-db [<parameters>]' before."
    echo
    warn "For more details about how to, use:"
    success "-> $(basename $0) save-db --help"
    exit 0
}

usage_save-db() {
    warn "Usage:"
    success "-> $(basename $0) save-db <DB-SERVER> [<parameters>]"
    echo
    info "-> Saves the databases of the given database server as sql files into 'initDB/<DB-SERVER>'."
    info "-> Use the service name from the yaml file for <DB-SERVER>, like 'mariadb1011' or 'mysql84'."
    info_b "-> IMPORTANT: Existing dumps with the same name are overwritten."
    echo
    echo
    warn "Parameters:"
    echo
    warn "-d, --databases="
    info "-> Only the given databases are saved, instead of all databases of the server."
    info "-> Put the value in quotes and separate multiple databases by space like 'db1 db2'."
    echo
    warn "-y, --yes"
    info "-> Don't ask for confirmation, if all databases are about to be saved."
    echo
    warn "-a, --archive"
    info "-> A copy of the saved databases is additionally archived in a subfolder within 'initDB/<DB-SERVER>'."
    info "-> If '-f' is not set, the subfolder is named with the current date, in this format 'yyyy-mm-dd'."
    echo
    warn "-f, --archive-folder="
    info "-> Set the subfolder within 'initDB/<DB-SERVER>', the databases are archived into."
    echo
    warn "--help"
    info "-> Show this help."
    echo
    echo
    info_b "Example:"
    success "-> $(basename $0) save-db mariadb1011 -d 'joomla4 joomla5'"
    info "-> Saves only the databases 'joomla4' and 'joomla5' into 'initDB/mariadb1011'."
    echo
    success "-> $(basename $0) save-db mariadb1011 -a"
    info "-> Asks for confirmation, then saves all databases and archives a copy into 'initDB/mariadb1011/yyyy-mm-dd'."
    exit 0
}

usage_restore-db() {
    warn "Usage:"
    success "-> $(basename $0) restore-db <DB-SERVER> [<parameters>]"
    echo
    info "-> Restores the dumps from 'initDB/<DB-SERVER>' into the running database server."
    info "-> Use the service name from the yaml file for <DB-SERVER>, like 'mariadb1011' or 'mysql84'."
    info_b "-> IMPORTANT: Every database with the same name as a dump is dropped and created again."
    echo
    echo
    warn "Parameters:"
    echo
    warn "-d, --databases="
    info "-> Only the dumps of the given databases are restored, instead of all dumps in the folder."
    info "-> Put the value in quotes and separate multiple databases by space like 'db1 db2'."
    info "-> The other dumps are moved into 'initDB/<DB-SERVER>/${DUMP_SKIP_FOLDER}' while restoring and moved back afterwards."
    echo
    warn "-y, --yes"
    info "-> Don't ask for confirmation, if all dumps are about to be restored."
    echo
    warn "--help"
    info "-> Show this help."
    echo
    echo
    info_b "Example:"
    success "-> $(basename $0) restore-db mariadb1011 -d 'joomla4'"
    info "-> Restores only 'initDB/mariadb1011/joomla4.sql' into the database 'joomla4', leaving all other databases untouched."
    exit 0
}

usage_cli() {
    warn "Usage: $(basename $0) cli"
    echo
    warn "cli <CONTAINER-NAME> [<parameters>][ '<COMMAND-TO-PASS>']"
    info "-> Uses 'docker exec -it <CONTAINER-NAME>' to launch into the cli in the container, or to execute the passed command."
    info "-> Use single quotes ' to pass the command to the container to be executed in it."
    echo
    echo
    warn "Parameters:"
    echo
    warn "-r, --as-root"
    info "-> If this option is set, the cli is startet as root, elsewhere as user."
    echo
    warn "-x, --xdebug"
    info "-> Launch into cli with xdebug enabled."
    echo
    echo
    info_b "Example:"
    success "-> $(basename $0) cli php80 -r 'apk add nodejs npm'"
    info "-> This will install in the 'php80' container the packages 'nodejs' and 'npm'."
    echo
    info_b "Same as:"
    success "-> $(basename $0) cli php80 -r"
    info "-> php80:/srv/www# add apk nodejs npm"
    exit 0
}

# Usage of tput
#
# tput bold # Select bold mode
# tput dim  # Select dim (half-bright) mode
# tput smul # Enable underline mode
# tput rmul # Disable underline mode
# tput rev  # Turn on reverse video mode
# tput smso # Enter standout (bold) mode
# tput rmso # Exit standout mode
#
# tput setab [1-7] # Set the background colour using ANSI escape
# tput setaf [1-7] # Set the foreground colour using ANSI escape
# tput sgr0        # Reset text format to the terminal's default
# tput bel         # Play a bell
#
# Num  Colour
# 0    black
# 1    red
# 2    green
# 3    yellow
# 4    blue
# 5    magenta
# 6    cyan
# 7    white

error() {
    tput setaf 1
    tput bold
    echo "ERROR:" "$@"
    tput sgr 0
    tput bel
}

warn() {
    tput setaf 3
    echo "$@"
    tput sgr 0
}

info() {
    tput setaf 7
    echo "$@"
    tput sgr 0
}

info_b() {
    tput setaf 7
    tput bold
    echo "$@"
    tput sgr 0
}

success() {
    tput setaf 2
    echo "$@"
    tput sgr 0
    tput cnorm
}

headline() {
    [ "$DEBUG" -eq 1 ] \
        && echo \
        && warn "--" "$@" "--"
}

log() {
    [ "$DEBUG" -eq 1 ] \
        && info "->" "$@"
}

log_b() {
    [ "$DEBUG" -eq 1 ] \
        && info_b "->" "$@"
}

log_s() {
    [ "$DEBUG" -eq 1 ] \
        && success "->" "$@"
}

log_w() {
    [ "$DEBUG" -eq 1 ] \
        && warn "->" "$@"
}

add_yaml_to_load() {
    local YAML_LIST_TO_LOAD=${LOAD_YAML:-}
    local CONTAINER_PATH="$1"

    if [ -f "$APP_BASEDIR/$CONTAINER_PATH/config.yml" ]; then
        LOAD_YAML="$YAML_LIST_TO_LOAD $APP_BASEDIR/$CONTAINER_PATH/config.yml"
    elif [ -f "$DOCKER_LAMP_BASEDIR/.config/$CONTAINER_PATH/config.yml" ]; then
        LOAD_YAML="$YAML_LIST_TO_LOAD $DOCKER_LAMP_BASEDIR/.config/$CONTAINER_PATH/config.yml"
    else
        echo
        error "docker compose configuration file for '$CONTAINER_PATH' not found!"
        warn "Searched for '$APP_BASEDIR/$CONTAINER_PATH/config.yml'"
        warn "and '$DOCKER_LAMP_BASEDIR/.config/$CONTAINER_PATH/config.yml'"
        exit 1
    fi

    log_s "$CONTAINER_PATH YAML loaded."
}

get_yaml_aliases() {
    local aliases=""

    for alias in $1; do
        aliases="${aliases}\n          - \"${alias}\""
    done

    printf "${aliases}"
}

get_yaml_list() {
    local list=""

    for item in $1; do
        list="${list}\n      - \"${item}\""
    done

    printf "${list}"
}

get_yaml_volumes() {
    local volumes=""

    for volume in $1; do
        volumes="${volumes}\n  ${volume}:"
    done

    printf "${volumes}"
}

create_gateway_and_container_ipv4() {
    local _ip4="${DL_SUBNET%/*}"
    local _old_remote_ip="$REMOTE_HOST_IP"

    REMOTE_HOST_IP="${_ip4%.*}.$((${_ip4##*.} + 1))"
    DL_BIND_IPv4="${_ip4%.*}.$((${_ip4##*.} + 2))"
    DL_BIND_INTERNAL_IPv4="${_ip4%.*}.$((${_ip4##*.} + 3))"
    DL_HTTPD_IPv4="${_ip4%.*}.$((${_ip4##*.} + 4))"
#    DL_DB_IPv4="${_ip4%.*}.$((${_ip4##*.} + 5))"
    DL_PMA_IPv4="${_ip4%.*}.$((${_ip4##*.} + 6))"
    DL_MAILCATCHER_IPv4="${_ip4%.*}.$((${_ip4##*.} + 7))"

    seq=20
    for var in $PHP_TO_USE; do
      # Construct name of environment variable
      IPv4_NAME="DL_${var@U}_IPv4"
      # Declare global variable with dynamic name and assign address
      declare -g ${IPv4_NAME}="${_ip4%.*}.$((${_ip4##*.} + $seq))"
      log "PHP Version ${IPv4_NAME}: $(eval echo "\$$IPv4_NAME")"
      seq=$((seq + 1))
    done

    seq=40
    for var in $DATABASE_TO_USE; do
      # Construct name of environment variable address
      IPv4_NAME="DL_${var@U}_IPv4"
      # Declare global variable with dynamic name and assign
      declare -g ${IPv4_NAME}="${_ip4%.*}.$((${_ip4##*.} + $seq))"
      log "Database ${IPv4_NAME}: $(eval echo "\$$IPv4_NAME")"
      seq=$((seq + 1))
    done

    #DNS_A=${DNS_A//$_old_remote_ip/$REMOTE_HOST_IP}
    DNS_A=${DNS_A//$_old_remote_ip/127.0.0.1}
    DNS_B=${DNS_A//127.0.0.1/$DL_HTTPD_IPv4}
}

check_override_folders() {
    local needed=(
        "ca"
        "httpd/apache24"
        "initDB/mariadb104"
        "initDB/mariadb105"
        "initDB/mariadb106"
        "initDB/mariadb1011"
        "initDB/mariadb114"
        "initDB/mysql57"
        "initDB/mysql80"
        "initDB/mysql83"
        "initDB/mysql84"
        "initDB/mysql93"
        "initDB/mysql94"
        "initDB/mysql95"
        "php/php56"
        "php/php74"
        "php/php80"
        "php/php81"
        "php/php82"
        "php/php83"
        "php/php84"
    )

    for folder in "${needed[@]}"; do
        if ! test -d "${APP_BASEDIR}/${folder}"; then
            success "Create: ${APP_BASEDIR}/${folder}"
            mkdir -p ${APP_BASEDIR}/${folder}
        fi
    done
}

iterate_databases() {
    local _command="$1"
    local _db_to_restore="$2"

    if [ "${_command}" == "restore" ]; then
        for var in ${_db_to_restore}; do
            restore_db "${var}"
        done
    fi

    if [ "${_command}" == "save" ]; then
        for var in ${DATABASE_TO_USE}; do
            save_db "${var}"
        done
    fi
}

start_server() {
    local _db_volume_exist=""
    local _db_to_restore=""

    check_override_folders

    #if [ "$USE_BIND" -eq 1 ]; then
        create_certs
    #fi

    for var in ${DATABASE_TO_USE}; do
        local _db_volume_exist=$(docker volume ls --filter=name=${COMPOSE_PROJECT_NAME} | grep "${COMPOSE_PROJECT_NAME}_${var}")
        [ -z "${_db_volume_exist}" ] && _db_to_restore="${_db_to_restore} ${var}"
    done

    _db_to_restore="$(echo ${_db_to_restore})"

    warn "Start server:"
    ${DOCKER_COMPOSE_CALL} up -d ${INIT_DL_BIND} --force-recreate \
        && success "Server started."
    info ""

    if [ -z "${DATABASE_BIND_MOUNT_PATH}" ]; then
      iterate_databases "restore" "${_db_to_restore}"
    fi
}

restart_server() {
    ( [ -f "${DOCKER_COMPOSE_YAML}" ] && [ -z "$(${DOCKER_COMPOSE_CALL} ps -q)" ] ) \
        && warn "Server is not running." && exit 0

    stop_server

    #if [ "$USE_BIND" -eq 1 ]; then
    #    create_certs
    #fi

    start_server
    #warn "Start server:"
    #$DOCKER_COMPOSE_CALL up -d --force-recreate \
    #    && success "Server restarted."
    #info ""
}

shutdown_server() {
    ( [ -f "${DOCKER_COMPOSE_YAML}" ] && [ -z "$(${DOCKER_COMPOSE_CALL} ps -q)" ] ) \
        && warn "Server is not running." \
        && exit 0

    if [ -z "${DATABASE_BIND_MOUNT_PATH}" ]; then
      [ -z "${SKIP_SAVE_DATABASES}" ] \
        && iterate_databases "save" \
        || success "Skip save database(s)."
    fi

    warn "Shutdown server:"
    ${DOCKER_COMPOSE_CALL} down -v
    success "Server shut down."
}

stop_server() {
    ( [ -f "${DOCKER_COMPOSE_YAML}" ] && [ -z "$(${DOCKER_COMPOSE_CALL} ps -q)" ] ) \
        && warn "Server is not running." && exit 0

    warn "Stop server:"
    ${DOCKER_COMPOSE_CALL} down
    warn "Removing volumes:"
    docker volume ls --filter=name=${COMPOSE_PROJECT_NAME} \
        | awk 'NR > 1 {print $2}' \
        | grep -v -F -f <(echo "${DATABASE_TO_USE}" | tr ' ' '\n') \
        | xargs docker volume rm --force \
        | xargs echo "Volumes removed:"
    success "Server is stoped."
}

save_db() {
    local db_to_save="$1"

    [ -z "$(${DOCKER_COMPOSE_CALL} ps -q ${db_to_save})" ] \
        && warn "Database server '${db_to_save}' is not running." && exit 0

    # Use an array, while the value of "SAVE_DB" can contain spaces.
    local -a envs=()
    [ "${ARCHIVE_DATABASES:-0}" -eq 1 ] && envs+=(-e "ARCHIVE=1")
    [ ! -z "${ARCHIVE_FOLDER}" ] && envs+=(-e "ARCHIVE_FOLDER=${ARCHIVE_FOLDER}")

    # If databases are selected, only these are saved, otherwise all of them.
    [ ! -z "${DATABASES_TO_HANDLE}" ] && envs+=(-e "SAVE_DB=${DATABASES_TO_HANDLE}")

    local shell="sh"
    case "${db_to_save}" in
        mysql57|mysql80|mysql83|mysql84|mysql93|mysql94|mysql95)
            shell="bash"
            ;;
    esac

    warn "Save databases for ${db_to_save}:"
    docker exec -it --privileged "${envs[@]}" ${COMPOSE_PROJECT_NAME}_${db_to_save} /usr/bin/env ${shell} -c "/usr/local/bin/backup-databases"
    info ""
}

delete_obsolete_images() {
    local OBSOLETE_IMAGES="$(docker images -f "dangling=true" -q)"

    [ -z "${OBSOLETE_IMAGES}" ] \
        && success "No obsolete images found." \
        && exit 0

    warn "Found obsolete Images:"
    info "$OBSOLETE_IMAGES"

    local ERROR_DELETE_OBSOLETE="$(docker rmi ${OBSOLETE_IMAGES} >/dev/null 2>&1)"

    [ -z "${ERROR_DELETE_OBSOLETE}" ] \
        && success "Obsolete images deleted." \
        || error "$ERROR_DELETE_OBSOLETE"
}

create_certs() {
    [ ! -z "${SSL_LOCALDOMAINS}" ] \
        && MINICA_DEFAULT_DOMAINS="${MINICA_DEFAULT_DOMAINS},${SSL_LOCALDOMAINS}"

    [ ! -z "${SSL_DOMAINS}" ] \
        && MINICA_DEFAULT_DOMAINS="${MINICA_DEFAULT_DOMAINS} ${SSL_DOMAINS}"

    MINICA_DEFAULT_DOMAINS="$(echo "${MINICA_DEFAULT_DOMAINS}" | sed "s/, /,/g")"

    warn "Start creating SSL certificates:"

    for domain in ${MINICA_DEFAULT_DOMAINS}; do
        local first_domain=$(echo ${domain} | cut -d ',' -f1)

        info ""
        log "domain: $domain"
        log "first_domain: $first_domain"

        if [ -d "${MINICA_BASEDIR}/${first_domain}" ]; then
            success "Skipping the creation of the certificate bundle because it exists, in:" "$MINICA_BASEDIR/$first_domain"
            info "-> Bundle for: $domain"
            continue
        fi

        success "Create certificate bundle in:" "$MINICA_BASEDIR/$first_domain"
        info "-> Bundle for: $domain"

        docker run --user ${DOCKER_PASS_USER} -it --rm \
            -v "${MINICA_BASEDIR}:/certs" \
            degobbis/minica \
            --ca-cert minica-root-ca.pem \
            --ca-key minica-root-ca-key.pem \
            --domains ${domain}
        echo
    done

    info ""
    success "All certificates created."
    info ""
}

# Name of the folder inside the dump directory, the dumps not to be restored are moved into.
# It starts with a dot, so it is not matched by the glob over "/docker-entrypoint-initdb.d/*"
# in the "restore-databases" script of the database container.
DUMP_SKIP_FOLDER=".restore-skip"

# Returns the database name for a dump file, by removing the ".sql" or ".sql.gz" extension.
get_dump_db_name() {
    local dump_name="$(basename "$1")"

    dump_name="${dump_name%.gz}"

    echo "${dump_name%.sql}"
}

# Moves the dumps back, that were set aside for a selective restore.
# It is called by a trap as well, so it has to be idempotent.
move_back_skipped_dumps() {
    local skip_folder="$1"

    [ ! -d "${skip_folder}" ] && return 0

    local dump=""
    for dump in "${skip_folder}"/*; do
        [ -e "${dump}" ] && mv -f "${dump}" "$(dirname "${skip_folder}")/"
    done

    rmdir "${skip_folder}" 2>/dev/null

    return 0
}

# Moves all dumps, that are not requested, into the skip folder, so that the "restore-databases"
# script of the database container doesn't find them and only restores the requested databases.
set_aside_unselected_dumps() {
    local dump_dir="$1"
    local databases="$2"
    local skip_folder="${dump_dir}/${DUMP_SKIP_FOLDER}"

    [ ! -d "${dump_dir}" ] \
        && error "No dump directory found: '${dump_dir}'" && return 1

    # Check all requested databases before moving anything.
    local missing=""
    local database=""
    for database in ${databases}; do
        [ ! -f "${dump_dir}/${database}.sql" ] && [ ! -f "${dump_dir}/${database}.sql.gz" ] \
            && missing="${missing} ${database}"
    done

    if [ ! -z "${missing}" ]; then
        error "No dump found in '${dump_dir}' for:" "$(echo ${missing})"
        return 1
    fi

    mkdir -p "${skip_folder}" || return 1

    local dump=""
    local db_name=""
    for dump in "${dump_dir}"/*.sql "${dump_dir}"/*.sql.gz "${dump_dir}"/*.sh; do
        [ ! -f "${dump}" ] && continue

        db_name="$(get_dump_db_name "${dump}")"

        case " ${databases} " in
            *" ${db_name} "*)
                continue
                ;;
        esac

        mv -f "${dump}" "${skip_folder}/" || return 1
    done

    return 0
}

# Asks for confirmation, before a command handles all databases of a server.
# It is skipped, if databases are selected with "-d", or the confirmation is given with "-y".
# $1 = "save" or "restore", $2 = the database server
confirm_all_databases() {
    local action="$1"
    local db_server="$2"

    [ "${SKIP_CONFIRMATION:-0}" -eq 1 ] && return 0
    [ ! -z "${DATABASES_TO_HANDLE}" ] && return 0

    local dump_dir="${APP_BASEDIR}/initDB/${db_server}"

    echo
    if [ "${action}" = "save" ]; then
        warn "ALL databases of '${db_server}' are about to be saved into 'initDB/${db_server}'."
        info "-> Every dump already there with the same name is overwritten."
    else
        warn "ALL dumps in 'initDB/${db_server}' are about to be restored into '${db_server}'."
        info "-> Every database with the same name as a dump is dropped and created again."

        local found=""
        local dump=""
        for dump in "${dump_dir}"/*.sql "${dump_dir}"/*.sql.gz; do
            [ -f "${dump}" ] && found="${found} $(get_dump_db_name "${dump}")"
        done

        [ -z "${found}" ] \
            && warn "No dumps found in '${dump_dir}'." \
            && exit 0

        info "-> Databases to restore:" "$(echo ${found})"
    fi

    info "-> Use '-d <db-name>' to handle single databases only, or '-y' to skip this question."
    echo

    [ ! -t 0 ] \
        && error "No terminal available to ask for confirmation." \
        && warn "Use '-y' to confirm all databases, or '-d' to select single databases." \
        && exit 1

    local answer=""
    read -r -p "Continue with ALL databases? [y/N] " answer
    echo

    case "${answer}" in
        j|J|y|Y|ja|Ja|yes|Yes|JA|YES)
            return 0
            ;;
    esac

    warn "Aborted, no database was touched."
    exit 0
}

restore_db() {
    local db_to_restore="$1"
    local dump_dir="${APP_BASEDIR}/initDB/${db_to_restore}"
    local skip_folder="${dump_dir}/${DUMP_SKIP_FOLDER}"

    [ -z "$(${DOCKER_COMPOSE_CALL} ps -q ${db_to_restore})" ] \
        && warn "Database server '$db_to_restore' is not running." && exit 0

    # A previous run may have been interrupted before the dumps were moved back.
    move_back_skipped_dumps "${skip_folder}"

    # If databases are selected, all other dumps are set aside during the restore.
    if [ ! -z "${DATABASES_TO_HANDLE}" ]; then
        set_aside_unselected_dumps "${dump_dir}" "${DATABASES_TO_HANDLE}" \
            || { move_back_skipped_dumps "${skip_folder}"; return 1; }

        trap "move_back_skipped_dumps '${skip_folder}'" EXIT INT TERM
    fi

    local shell="sh"
    case "${db_to_restore}" in
        mysql57|mysql80|mysql83|mysql84|mysql93|mysql94|mysql95)
            shell="bash"
            ;;
    esac

    warn "Restore databases for ${db_to_restore}:"
    docker exec -it --privileged ${COMPOSE_PROJECT_NAME}_${db_to_restore} /usr/bin/env ${shell} -c "/usr/local/bin/restore-databases"
    info ""

    if [ ! -z "${DATABASES_TO_HANDLE}" ]; then
        trap - EXIT INT TERM
        move_back_skipped_dumps "${skip_folder}"
    fi
}

update_images() {
    local yaml_file_for_update="${DOCKER_LAMP_BASEDIR}/.config/update-images.yml"

    [ -f "${DOCKER_COMPOSE_YAML}" ] && yaml_file_for_update="${DOCKER_COMPOSE_YAML}"

    docker compose -f ${yaml_file_for_update} pull
}

cli_container() {
    local params="--user ${DOCKER_PASS_USER} "
    local shell="sh"
    local call_as_root="${AS_ROOT:-0}"


    # TODO: Set it only on CLI call for CLI debugging
    local env=' -e XDEBUG_CONFIG= '

    case "${CLI_CONTAINER}" in
        php80|php81|php82|php83|php84)
            env+=' -e XDEBUG_SESSION=1 '
            ;;
        mysql57|mysql80|mysql83|mysql84|mysql93|mysql94|mysql95)
            shell="bash"
            params="--user 999:999 "
            ;;
    esac

    [ -z "$(${DOCKER_COMPOSE_CALL} ps -q ${CLI_CONTAINER})" ] \
        && warn "The container '$CLI_CONTAINER' is not running." && exit 0

    if [[ "$(docker context show)" = "desktop-linux" ]]; then
        success "Docker Desktop for Linux in usage."
        warn "Logged in as root!"
        call_as_root="1"
    fi

    [ "${call_as_root}" -eq 1 ] && params="--privileged "
    [ "${CLI_WITH_XDEBUG:-0}" -eq 0 ] && env=""

    headline "Before starting CLI for '$CLI_CONTAINER'"
    log "shell: $shell"
    log "env: $env"
    log "params: $params"
    log "COMMAND_TO_PASS: $COMMAND_TO_PASS"

    [ ! -z "${COMMAND_TO_PASS}" ] \
        && docker exec -it ${params}${env}${COMPOSE_PROJECT_NAME}_${CLI_CONTAINER} /usr/bin/env ${shell} -cx "${COMMAND_TO_PASS}" \
        || docker exec -it ${params}${env}${COMPOSE_PROJECT_NAME}_${CLI_CONTAINER} /usr/bin/env ${shell}
}

quote () {
    local quoted=${1//\'/\'\\\'\'};
    printf "'%s'" "${quoted}"
}

# find . -maxdepth 1 -type f ! -name "*.md" ! -name "*.txt"
