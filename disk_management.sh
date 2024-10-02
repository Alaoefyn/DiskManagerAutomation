#!/bin/bash

# checks for tools are installed or not
install_tools() {
    sudo apt update
    sudo apt install -y smartmontools parted cryptsetup ntfs-3g dialog
    whiptail --msgbox "All necessary tools have been installed!" 8 45
    main_menu
}

main_menu() {
    OPTION=$(whiptail --title "Disk Management Tool" --menu "Choose an option" 15 60 10 \
        "1" "Check if Disk is Read-Only" \
        "2" "Run S.M.A.R.T. Test" \
        "3" "Check Disk Health" \
        "4" "Zero or Quick Format Disk" \
        "5" "Force Remove Read-Only Attribute" \
        "6" "Show Disks and Partitions" \
        "7" "Filesystem Creation (mkfs)" \
        "8" "Encrypt/Decrypt Disk" \
        "9" "Change Disk Format (MBR/GPT)" \
        "10" "Install Necessary Tools" 3>&1 1>&2 2>&3)

    case $OPTION in
        1) check_read_only ;;
        2) run_smart_test ;;
        3) check_disk_health ;;
        4) format_disk ;;
        5) remove_read_only ;;
        6) show_disks ;;
        7) create_filesystem ;;
        8) encrypt_decrypt_disk ;;
        9) change_disk_format ;;
        10) install_tools ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
}

check_read_only() {
    whiptail --msgbox "This option will check if a disk is mounted as read-only or read-write.\nYou'll need to provide the device name (e.g., /dev/sda)." 12 60
    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    RO_STATUS=$(lsblk -o NAME,RO | grep $(basename $DEVICE) | awk '{print $2}')
    if [ "$RO_STATUS" -eq 1 ]; then
        whiptail --msgbox "The disk is read-only!" 8 45
    else
        whiptail --msgbox "The disk is writable!" 8 45
    fi
    main_menu
}

run_smart_test() {
    whiptail --msgbox "This option will run a quick S.M.A.R.T. test on the disk.\nS.M.A.R.T. tests help assess the overall health and performance of a disk." 12 60
    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    smartctl -t short $DEVICE
    sleep 10  # Wait for the short test to complete
    RESULT=$(smartctl -a $DEVICE | grep -i result)
    whiptail --msgbox "S.M.A.R.T. Test Result:\n$RESULT" 12 60
    main_menu
}

check_disk_health() {
    whiptail --msgbox "This option will check the overall health of the disk using S.M.A.R.T.\nIt provides a basic assessment of the disk's condition." 12 60
    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    HEALTH=$(smartctl -H $DEVICE | grep -i overall)
    whiptail --msgbox "Disk Health Status:\n$HEALTH" 12 60
    main_menu
}

format_disk() {
    whiptail --msgbox "This option will allow you to either fully zero out the disk (slow) or perform a quick format (faster)." 12 60
    FORMAT_TYPE=$(whiptail --menu "Choose format type" 15 60 2 \
        "1" "Zero Format (Full)" \
        "2" "Quick Format" 3>&1 1>&2 2>&3)

    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    case $FORMAT_TYPE in
        1) dd if=/dev/zero of=$DEVICE bs=1M status=progress ;;
        2) mkfs.ext4 $DEVICE ;;  # Default to ext4 for quick format
    esac
    whiptail --msgbox "Format complete!" 8 45
    main_menu
}
# try to force-remove read-only state
remove_read_only() {
    whiptail --msgbox "This option will try to remove the read-only attribute from the disk.\nSeveral techniques will be attempted to make the disk writable." 12 60
    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    blockdev --setrw $DEVICE
    mount -o remount,rw $DEVICE
    RESULT=$(lsblk -o NAME,RO | grep $(basename $DEVICE))
    whiptail --msgbox "Updated Status:\n$RESULT" 12 60
    main_menu
}

show_disks() {
    whiptail --msgbox "This option will display all current disks and their partitions, excluding external devices like USB or SATA drives." 12 60
    DISKS=$(lsblk -e7 -o NAME,SIZE,TYPE)
    whiptail --msgbox "Current Disks and Partitions:\n$DISKS" 20 60
    main_menu
}

create_filesystem() {
    whiptail --msgbox "Filesystem Creation:\n\next4: The default Linux filesystem.\nNTFS: Commonly used for Windows partitions.\nvfat (FAT32): Used for USB drives and older systems.\nexFAT: Commonly used for larger external storage devices.\nxfs: High-performance file system for Linux." 15 60
    FS_TYPE=$(whiptail --menu "Choose filesystem type" 15 60 5 \
        "1" "ext4" \
        "2" "ntfs" \
        "3" "vfat (FAT32)" \
        "4" "exFAT" \
        "5" "xfs" 3>&1 1>&2 2>&3)

    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    case $FS_TYPE in
        1) mkfs.ext4 $DEVICE ;;
        2) mkfs.ntfs $DEVICE ;;
        3) mkfs.vfat $DEVICE ;;
        4) mkfs.exfat $DEVICE ;;
        5) mkfs.xfs $DEVICE ;;
    esac
    whiptail --msgbox "Filesystem creation complete!" 8 45
    main_menu
}

encrypt_decrypt_disk() {
    whiptail --msgbox "This option allows you to either encrypt a disk using LUKS (Linux Unified Key Setup) or decrypt an already encrypted disk.\nEncryption adds a layer of security to your data." 12 60
    OPTION=$(whiptail --menu "Choose encryption option" 15 60 2 \
        "1" "Encrypt with LUKS" \
        "2" "Decrypt LUKS" 3>&1 1>&2 2>&3)

    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    case $OPTION in
        1) cryptsetup luksFormat $DEVICE ;;
        2) cryptsetup luksOpen $DEVICE ;;
    esac
    whiptail --msgbox "Encryption/Decryption process complete!" 8 45
    main_menu
}

change_disk_format() {
    whiptail --msgbox "This option will change the disk's partition table format.\nGPT (GUID Partition Table) is modern and supports large disks.\nMBR (Master Boot Record) is older and used for compatibility." 12 60
    FORMAT=$(whiptail --menu "Choose partition table format" 15 60 2 \
        "1" "GPT" \
        "2" "MBR" 3>&1 1>&2 2>&3)

    DEVICE=$(whiptail --inputbox "Enter the device (e.g., /dev/sda)" 10 60 3>&1 1>&2 2>&3)
    case $FORMAT in
        1) parted $DEVICE mklabel gpt ;;
        2) parted $DEVICE mklabel msdos ;;
    esac
    whiptail --msgbox "Disk format changed!" 8 45
    main_menu
}

# Start the script
main_menu
