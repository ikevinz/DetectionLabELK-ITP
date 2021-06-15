#! /usr/bin/env bash

# This is the script that is used to provision the ftp server

install_vsftpd() {
    # Update system packages
    sudo apt update

    # Install vsftpd
    sudo apt install -y vsftpd
    sudo systemctl enable vsftpd
}

configure_vsftpd() {
    # Configure UFW
    sudo ufw allow from any to any port 20,21,10000:11000 proto tcp
    sudo service ufw start

    # Backup default conf (copy is saved to /vagrant/resources/ftp/vsftpd_default.conf)
    sudo cp /etc/vsftpd.conf  /etc/vsftpd.conf_default

    # Starts vsftpd
    sudo systemctl start vsftpd

    # Adds users to vsftpd allowed list
    sudo touch /etc/vsftpd.userlist
    
    for i in $(cat /vagrant/resources/ftp/users.txt); do
        # creates emulated enterprise users from /vagrant/resources/ftp/users.txt
        USERNAME=$(echo "$i" | cut -d: -f1)
        PASSWORD=$(echo "$i" | cut -d: -f2)
        USER_SHELL=$(echo "$i" | cut -d: -f3)
        
        sudo useradd -m "$USERNAME" -s "$USER_SHELL"
        echo "$USERNAME:$PASSWORD" | sudo chpasswd
        
        # Prepare User Home Directories
        sudo mkdir /home/$USERNAME/ftp
        sudo chown nobody:nogroup /home/$USERNAME/ftp
        sudo chmod a-w /home/$USERNAME/ftp
        sudo mkdir /home/$USERNAME/ftp/files
        sudo chown $USERNAME:$USERNAME /home/$USERNAME/ftp/files

        # Add user to vsftpd allowed list
        echo $USERNAME | sudo tee -a /etc/vsftpd.userlist
    done
}

secure_vsftpd() {
    # Generate SSL Cert
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem

    # Copy in vsftpd config
    # Changes applied:
    # - chroot jail
    # - SSL enabled
    # - write_enable=YES

    sudo cp /vagrant/resources/ftp/vsftpd.conf /etc/vsftpd.conf

    # Restart vsftpd
    sudo systemctl restart vsftpd.service
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

    echo "[$(date +%H:%M:%S)]: Securing FTP Server..."
    secure_vsftpd
    echo "[$(date +%H:%M:%S)]: Security Configuration Complete."

    echo "------------  FTP SETUP COMPLETE  ------------"
}

main
exit 0