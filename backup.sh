#!/bin/bash

# Ensure only root can run the script
if [ "$(id -u)" -ne 0 ]; then
    zenity --error --text="You must run this script as root!"
    exit 1
fi

LOG_FILE="/var/log/backup_script.log"
mkdir -p /var/log/backup_script

# Function to log actions
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# GUI to select source folder
SOURCE_DIR=$(zenity --file-selection --directory --title="Select the Source Directory")
if [ -z "$SOURCE_DIR" ]; then
    zenity --error --text="Source directory not selected!"
    exit 1
fi

# GUI to select destination folder
DEST_DIR=$(zenity --file-selection --directory --title="Select the Backup Destination Directory")
if [ -z "$DEST_DIR" ]; then
    zenity --error --text="Destination directory not selected!"
    exit 1
fi

# Choose backup frequency
FREQ=$(zenity --list --radiolist \
  --title="Select Backup Frequency" \
  --column="Select" --column="Frequency" \
  TRUE "Daily" FALSE "Weekly" FALSE "Monthly")

if [ -z "$FREQ" ]; then
    zenity --error --text="Backup frequency not selected!"
    exit 1
fi

# Confirm backup creation
zenity --question --text="Do you want to proceed with creating the backup job?"
if [ $? -ne 0 ]; then
    exit 1
fi

# Compress and backup function
backup_now() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_NAME="backup_$(basename "$SOURCE_DIR")_$TIMESTAMP.tar.gz"
    BACKUP_PATH="$DEST_DIR/$BACKUP_NAME"
    
    tar -czf "$BACKUP_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"
    
    if [ $? -eq 0 ]; then
        log_action "Backup successful: $BACKUP_PATH"
    else
        log_action "Backup failed!"
    fi
}

# Add cron job
CRON_CMD="bash $0 #AUTOBACKUP"
(crontab -l 2>/dev/null | grep -v '#AUTOBACKUP'; echo "$(case $FREQ in
    Daily) echo '0 2 * * *' ;;
    Weekly) echo '0 2 * * 0' ;;
    Monthly) echo '0 2 1 * *' ;;
esac) $CRON_CMD") | crontab -

# Run backup now
backup_now

# Final confirmation
zenity --info --text="Backup setup complete and backup performed. Cron job added for $FREQ backups."
