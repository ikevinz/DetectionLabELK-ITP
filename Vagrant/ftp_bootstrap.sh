#! /usr/bin/env bash

# This is the script that is used to provision the ftp server

install_vsftpd() {
    # Update system packages
    #sudo apt update
    #sudo dnf update

    # Install vsftpd
    #sudo apt install -y vsftpd
    sudo dnf install -y vsftpd
    sudo systemctl enable vsftpd --now
}

install_auditbeat() {
    # Install Auditbeat
    echo "[$(date +%H:%M:%S)]: Installing Filebeats..."
    cd /tmp/setup_temp
    curl -L -O https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-7.13.2-x86_64.rpm
    sudo rpm -vi auditbeat-7.13.2-x86_64.rpm
    echo "[$(date +%H:%M:%S)]: Auditbeat Installed!"
}

install_filebeat() {
    # Install Filebeats
    echo "[$(date +%H:%M:%S)]: Installing Filebeats..."
    mkdir /tmp/setup_temp
    cd /tmp/setup_temp
    curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.13.2-x86_64.rpm
    sudo rpm -vi filebeat-7.13.2-x86_64.rpm
    echo "[$(date +%H:%M:%S)]: Filebeats Installed!"
}

configure_vsftpd() {
    # Configure UFW
    #sudo ufw allow from any to any port 20,21,40000:50000 proto tcp
    sudo systemctl start firewalld
    sudo firewall-cmd --permanent --add-port=20-21/tcp
    sudo firewall-cmd --permanent --add-port=40000-50000/tcp
    #sudo service ufw start
    sudo firewall-cmd --reload

    # Backup default conf (copy is saved to /vagrant/resources/ftp/vsftpd_default.conf)
    #sudo cp /etc/vsftpd.conf  /vagrant/resources/ftp/vsftpd_default.conf
    sudo cp /etc/vsftpd/vsftpd.conf  /vagrant/resources/ftp/vsftpd_default.conf

    #Configure vsftpd.conf
    #sudo cp /vagrant/resources/ftp/vsftpd.conf /etc/vsftpd/vsftpd.conf  

    # Starts vsftpd
    #sudo systemctl start vsftpd

    # Adds users to vsftpd allowed list
    sudo touch /etc/vsftpd/vsftpd.userlist

    #Create User Home Directory
    sudo mkdir /etc/vsftpd/user_dir
    
    for i in $(cat /vagrant/resources/ftp/users.txt); do
        # creates emulated enterprise users from /vagrant/resources/ftp/users.txt
        USERNAME=$(echo "$i" | cut -d: -f1)
        PASSWORD=$(echo "$i" | cut -d: -f2)
        USER_SHELL=$(echo "$i" | cut -d: -f3)
        
        #sudo useradd -m $USERNAME -s $USER_SHELL
        sudo useradd -m $USERNAME
        echo "$USERNAME:$PASSWORD" | sudo chpasswd
        sudo chsh -s $USER_SHELL $USERNAME
        
        # Prepare User Home Directories
        sudo mkdir /home/$USERNAME/ftp
        #sudo chown nobody:nogroup /home/$USERNAME/ftp
        #sudo chown $USERNAME:$USERNAME /home/$USERNAME/ftp
        #sudo usermod -d /home/$USERNAME/ftp $USERNAME
        sudo chmod a-w /home/$USERNAME
        #sudo mkdir /home/$USERNAME/ftp/files
        #sudo chown $USERNAME:$USERNAME /home/$USERNAME/ftp/files
        sudo chmod -R 750 /home/$USERNAME/ftp
        sudo chown -R $USERNAME: /home/$USERNAME/ftp

        # Add user to vsftpd allowed list
        echo $USERNAME | sudo tee -a /etc/vsftpd/vsftpd.userlist
    done
}
configure_filebeat() {
  echo "[$(date +%H:%M:%S)]: Configuring Filebeat..."

  cat >/etc/filebeat/filebeat.yml <<EOF
  filebeat.inputs:
  - type: log
    enabled: false
    paths:
      - /var/log/auth.log
      - /var/log/syslog

  filebeat.config.modules:
    path: \${path.config}/modules.d/*.yml
    reload.enabled: true
    reload.period: 10s

  setup.kibana:
    host: "https://192.168.38.105:5601"
    username: vagrant
    password: vagrant
    ssl.enabled: true
    ssl.verification_mode: none

  setup.dashboards.enabled: true
  setup.ilm.enabled: false

  output.elasticsearch:
    hosts: ["https://192.168.38.105:9200"]
    ssl.enabled: true
    ssl.verification_mode: none
EOF

  cat >/etc/filebeat/modules.d/osquery.yml.disabled <<EOF
  - module: osquery
    result:
      enabled: true

      # Set custom paths for the log files. If left empty,
      # Filebeat will choose the paths depending on your OS.
      var.paths: ["/var/log/kolide/osquery_result"]
EOF
  filebeat --path.config /etc/filebeat modules enable osquery

  echo "[$(date +%H:%M:%S)]: FileBeats forwarding configuration complete."
}

configure_auditbeat() {
  echo "[$(date +%H:%M:%S)]: Configuring Auditbeat..."

	cat >/etc/auditbeat/auditbeat.yml <<EOF
auditbeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.period: 10s
  reload.enabled: true
auditbeat.max_start_delay: 10s

auditbeat.modules:
- module: auditd
  audit_rule_files: [ '\${path.config}/audit.rules.d/*.conf' ]
  audit_rules: |
- module: file_integrity
  paths:
  - /bin
  - /usr/bin
  - /sbin
  - /usr/sbin
  - /etc
- module: system
  state.period: 12h
  user.detect_password_changes: true
  login.wtmp_file_pattern: /var/log/wtmp*
  login.btmp_file_pattern: /var/log/btmp*
setup.template.settings:
  index.number_of_shards: 1
setup.kibana:
  host: "https://192.168.38.105:5601"
  username: vagrant
  password: vagrant
  ssl.enabled: true
  ssl.verification_mode: none

setup.dashboards.enabled: true
setup.ilm.enabled: false

output.elasticsearch:
  hosts: ["https://192.168.38.105:9200"]
  ssl.enabled: true
  ssl.verification_mode: none
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
EOF
	mv /etc/auditbeat/audit.rules.d/sample-rules.conf.disabled /etc/auditbeat/audit.rules.d/sample-rules.conf
	/bin/systemctl enable auditbeat.service
	/bin/systemctl start auditbeat.service

  echo "[$(date +%H:%M:%S)]: Auditbeat configuration complete."
}

secure_vsftpd() {
    sudo mkdir /etc/vsftpd/private
    # Generate SSL Cert
    #sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/vsftpd/private/vsftpd.pem -out /etc/vsftpd/private/vsftpd.pem -subj "/C=SG/ST=Singapore/L=Singapore/O=DSO/CN=DSO"
    
    # Copy in vsftpd config
    # Changes applied:
    # - chroot jail
    # - SSL enabled
    # - write_enable=YES

    sudo cp /vagrant/resources/ftp/vsftpd.conf /etc/vsftpd.conf

    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

    # Create vsftpd log file
    sudo touch /var/log/vsftpd.log

    # Restart vsftpd
    sudo systemctl start vsftpd.service
    sudo systemctl restart sshd
}

cleanup(){
    #Deleting temp files
    rm -rf /tmp/setup_temp
}

main() {
    echo "------------  FTP BOOTSTRAP RUNNING  ------------"
    sudo timedatectl set-timezone Asia/Singapore

    echo "[$(date +%H:%M:%S)]: Setting Up FTP Server..."
    install_vsftpd
    install_filebeat
    install_auditbeat
    echo "[$(date +%H:%M:%S)]: Installation Complete."

    echo "[$(date +%H:%M:%S)]: Configuring FTP Server..."
    configure_vsftpd
    configure_filebeat
    configure_auditbeat
    echo "[$(date +%H:%M:%S)]: Configuration Complete."

    echo "[$(date +%H:%M:%S)]: Securing FTP Server..."
    secure_vsftpd
    echo "[$(date +%H:%M:%S)]: Security Configuration Complete."

    echo "[$(date +%H:%M:%S)]: Cleaning Up..."
    cleanup
    echo "[$(date +%H:%M:%S)]: Clean up complete."

    echo "------------  FTP SETUP COMPLETE  ------------"
}

main
exit 0