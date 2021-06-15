#! /usr/bin/env bash

# This is the script that is used to provision the ftp server

install_vsftpd() {
    # Update system packages
    sudo apt update

    # Install vsftpd
    sudo apt install -y vsftpd
    sudo systemctl enable vsftpd
}

configure_vsftpd () {
    # Configure UFW
    sudo ufw allow 20/tcp
    sudo ufw allow 21/tcp

    # Backup default conf
    sudo cp /etc/vsftpd.conf  /etc/vsftpd.conf_default

    # Starts vsftpd
    sudo systemctl start vsftpd
}

main() {
    echo "------------  FTP BOOTSTRAP RUNNING  ------------"
    sudo timedatectl set-timezone Asia/Singapore

    echo "[$(date +%H:%M:%S)]: Setting Up FTP Server..."
    install_vsftpd
    echo "[$(date +%H:%M:%S)]: Installation Complete."

    echo "[$(date +%H:%M:%S)]: Configuring FTP Server..."
    configure_vsftpd
    echo "[$(date +%H:%M:%S)]: Configuration Complete."

    echo "------------  FTP SETUP COMPLETE  ------------"
}

main
exit 0