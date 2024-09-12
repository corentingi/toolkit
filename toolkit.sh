#!/bin/bash

command=$1

db_command_group() {
    # Backup and restore a MySQL database

    # Assigning command line arguments and environment variables
    command=$1

    mysql_arguments=""
    [[ -z "$DB_HOST" ]] || mysql_arguments+=" -h "$DB_HOST
    [[ -z "$DB_PORT" ]] || mysql_arguments+=" -P "$DB_PORT
    [[ -z "$DB_USER" ]] || mysql_arguments+=" -u "$DB_USER
    [[ -z "$DB_PASSWORD" ]] || mysql_arguments+=" -p"$DB_PASSWORD

    list_database() {
        mysql $mysql_arguments -e "SHOW DATABASES;"
    }

    # Function for backing up the database
    backup_database() {
        database_name=${1:-$DB_NAME}
        backup_path=${2}

        # default name
        current_datetime=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
        default_file_name="${current_datetime}_${database_name}_backup.sql"

        if [ -z $backup_path ]; then
            backup_path=$default_file_name
        elif [ -d $backup_path ]; then
            backup_path=${backup_path}/${default_file_name}
        fi

        echo "Starting backup for database $database_name..."
        mysqldump $mysql_arguments $database_name > "${backup_path}"
        echo "Backup completed: ${backup_path}"
    }

    # Function for restoring the database
    restore_database() {
        database_name=${1:-$DB_NAME}
        backup_path=${2}

        if [ ! -r $backup_path ]; then
            echo "Can't read from file: ${backup_path}"
            exit 1
        fi

        echo "Starting restore for database $database_name..."
        mysql $mysql_arguments $database_name < "${backup_path}"
        echo "Restore completed for $database_name"
    }

    # Check for the command and call the appropriate function
    case $command in
        list)
            list_database
            ;;
        backup)
            backup_database ${@:2}
            ;;
        restore)
            restore_database ${@:2}
            ;;
        *)
            echo "Invalid command. Use 'backup' or 'restore'."
            ;;
    esac
}


magick_command_directory() {
    source_directory=$1
    dest_directory=$2
    commands=${@:3}

    if [ ! -d $source_directory ]; then
        echo "Source directory doesn't exist"
        exit 1
    fi
    if [ ! -d $dest_directory ]; then
        echo "Destination directory doesn't exist"
        exit 1
    fi

    for src_file in $source_directory; do
        # Extract file name without extension
        filename=$(basename -- "$svg_file")
        extension="${filename##*.}"
        filename_no_ext="${filename%.*}"

        dest_file=$dest_directory/${filename_no_ext}-converted.${extension}
        magick $src_file $commands $dest_file

        if [ $? -ne 0 ]; then
            echo "Error resizing $src_file"
            exit 1
        else
            echo "Applied $commands to $dest_file"
        fi
    done
}


magick_command_group() {
    if ! command -v magick &> /dev/null; then
        echo "Image Magick is not installed"
        exit 1
    fi

    magick_batch() {
        source_directory=$1
        dest_directory=$2
        dest_extension=$3
        commands=${@:4}

        if [ ! -d $source_directory ]; then
            echo "Source directory doesn't exist"
            exit 1
        fi
        if [ ! -d $dest_directory ]; then
            echo "Destination directory doesn't exist"
            exit 1
        fi

        for src_file in $source_directory/*; do
            # Extract file name without extension
            filename=$(basename -- "$src_file")
            filename_no_ext="${filename%.*}"

            dest_file=$dest_directory/${filename_no_ext}-converted.${dest_extension}
            magick $src_file $commands $dest_file

            if [ $? -ne 0 ]; then
                echo "Error resizing $src_file"
                exit 1
            else
                echo "Applied $commands to $dest_file"
            fi
        done
    }

    magick_inplace() {
        source_directory=$1
        commands=${@:4}

        if [ ! -d $source_directory ]; then
            echo "Source directory doesn't exist"
            exit 1
        fi

        for src_file in $source_directory/*; do
            magick $src_file $commands $src_file

            if [ $? -ne 0 ]; then
                echo "Error resizing $src_file"
                exit 1
            else
                echo "Applied $commands to $src_file"
            fi
        done
    }

    # Check for the command and call the appropriate function
    case $1 in
        batch)
            magick_batch ${@:2}
            ;;
        inplace)
            magick_inplace ${@:2}
            ;;
        *)
            echo "Invalid command. Use 'install' or 'uninstall'."
            ;;
    esac
}

self_command_group() {
    command_name="toolkit"

    install_script() {
        script_location="$(realpath ${BASH_SOURCE[0]})"
        echo "Linking command '${command_name}' to '${script_location}'"
        ln -s "${script_location}" "/usr/local/bin/${command_name}"
    }

    uninstall_script() {
        echo "Removing link in '/usr/local/bin/alk'"
        unlink "/usr/local/bin/${command_name}"
    }

    # Check for the command and call the appropriate function
    case $1 in
        install)
            install_script
            ;;
        uninstall)
            uninstall_script
            ;;
        *)
            echo "Invalid command. Use 'install' or 'uninstall'."
            ;;
    esac
}

# Check for the command and call the appropriate function
case $command in
    db)
        db_command_group ${@:2}
        ;;
    magick)
        magick_command_group ${@:2}
        ;;
    self)
        self_command_group ${@:2}
        ;;
    *)
        cat <<EOF
usage : toolkit <command> [<args>]

db: Handle database dump and restore actions
magick: Handle images with batch actions
self: Manage this tool
EOF
        ;;
esac
