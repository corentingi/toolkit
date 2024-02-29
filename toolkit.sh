#!/bin/bash

command=$1

db_command_group() {
    # Backup and restore a MySQL database

    # Assigning command line arguments and environment variables
    command=$1
    database_name=${2:-$DB_NAME}

    backup_file_name="${database_name}_backup.sql"
    backup_path=${3:-$backup_file_name}
    if [ -d $backup_path ]; then
        backup_path=${3}/${backup_file_name}
    fi

    mysql_arguments=""
    [[ -z "$DB_HOST" ]] || mysql_arguments+=" -h "$DB_HOST
    [[ -z "$DB_PORT" ]] || mysql_arguments+=" -P "$DB_PORT
    [[ -z "$DB_USER" ]] || mysql_arguments+=" -u "$DB_USER
    [[ -z "$DB_PASSWORD" ]] || mysql_arguments+=" -p"$DB_PASSWORD

    # Function for backing up the database
    backup_database() {
        echo "Starting backup for database $database_name..."
        mysqldump $mysql_arguments $database_name > "${backup_path}"
        echo "Backup completed: ${backup_path}"
    }

    # Function for restoring the database
    restore_database() {
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
    self)
        self_command_group ${@:2}
        ;;
    *)
        echo "Invalid command. Use 'db'."
        ;;
esac
