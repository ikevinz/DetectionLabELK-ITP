#! /usr/bin/env bash

# This is the script that is used to provision the kali host
#! /usr/bin/env bash

# This is the script that is used to provision the kali host

install_filebeats() {
    # Install Filebeats
    echo "[$(date +%H:%M:%S)]: Installing Filebeats..."
    mkdir /tmp/setup_temp
    cd /tmp/setup_temp
    curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.13.0-amd64.deb
    sudo dpkg -i filebeat-7.13.0-amd64.deb
    echo "[$(date +%H:%M:%S)]: Filebeats Installed!"
}

configure_rsyslog() {
    # Configure rsyslog
    echo "[$(date +%H:%M:%S)]: Configuring rsyslog for shell command collection..."
    
    # Creating rsyslog conf file
    cd /etc/rsyslog.d
    echo "local6.*  /var/log/zsh.log" >> zsh.conf
    
    # Create the file under /var/log
    sudo touch /var/log/zsh.log
    
    echo "[$(date +%H:%M:%S)]: Rsyslog configuration complete."
}

configure_zsh() {
    # Configure zsh
    echo "[$(date +%H:%M:%S)]: Configuring ZSH..."
    
    # Modifying the .zshrc file for Kali
    sed -i '/^setopt hist_verify/a # ZSH Config for Filebeats/ELK\nsetopt INC_APPEND_HISTORY' ~/.zshrc
    sed -i "/^precmd() {/a     # Logging zsh commands to rsyslog\n    eval 'RETRN_VAL=\$?;logger -S 10000 -p local6.debug \"{\"user\": \"\$(whoami)\", \"path\": \"\$(pwd)\", \"pid\": \"\$\$\", \"b64_command\": \"\$(history | tail -n1 | /usr/bin/sed \"s/[ 0-9 ]*//\" | base64 -w0 )\", \"status\": \"\$RETRN_VAL\"}\"'" ~/.zshrc
    
    
    # Modifying root's zshrc
    sudo cp ~/.zshrc /root/.zshrc
    
    # Modifying /etc/zsh/zshrc
    #cd /etc/zsh
    #sudo (echo $'\n'; echo >> zshrc
    # Reloading zsh
    source ~/.zshrc
    
    echo "[$(date +%H:%M:%S)]: ZSH configuration complete."
}

configure_filebeat() {
    # Configure ELK Forwarding
    echo "[$(date +%H:%M:%S)]: Configuring ELK & FileBeats forwarding..."
    
    # Configuring filebeat.yml
    #cd /etc/filebeat
    
    # Enable logging
    #sudo sed -zi "s/- type: log\n\n  # Change to true to enable this input configuration.\n  enabled: false/- type: log\n\n  # Change to true to enable this input configuration.\n  enabled: true/" filebeat.yml
    
    # Enable Logstash, disable EL forwarding
    #sudo sed -i 's/output.elasticsearch/#output.elasticsearch/g' filebeat.yml
    #sudo sed 's/#output.logstash/output.logstash/g' filebeat.yml
    
    # Configure ELK host (CLS) on port 5044
    #sudo sed -i 's/.*hosts: ["localhost:9200"]/  #hosts: [\"192.168.38.105:9200\"]/' filebeat.yml
    #sudo sed 's/#hosts: ["localhost:5044"].*/hosts: [\"192.168.38.105:5044\"]/g' filebeat.yml
    
    # Configuring filebeat.yml
    cat >/etc/filebeat/filebeat.yml <<EOF
    filebeat.inputs:
    - type: log
      enabled: false
      paths:
        - /var/log/zsh.log
    
    filebeat.config.modules:
      path: \${path.config}/modules.d/*.yml
      reload.enabled: true
      reload.period: 10s
    
    output.logstash:
      hosts: ["192.168.38.105:5044"]

    #- module: zeek
      capture_loss:
        #enabled: true
      connection:
        #enabled: true
      dce_rpc:
        #enabled: true
      dhcp:
        #enabled: true
      dnp3:
        #enabled: true
      dns:
        #enabled: true
      dpd:
        #enabled: true
      files:
        #enabled: true
      ftp:
        #enabled: true
      http:
        #enabled: true
      intel:
        #enabled: true
      irc:
        #enabled: true
      kerberos:
        #enabled: true
      modbus:
        #enabled: true
      mysql:
        #enabled: true
      notice:
        #enabled: true
      ntlm:
        #enabled: true
      ocsp:
        #enabled: true
      pe:
        #enabled: true
      radius:
        enabled: true
      rdp:
        enabled: true
      rfb:
        enabled: true
      signature:
        enabled: true
      sip:
        enabled: true
      smb_cmd:
        enabled: true
      smb_files:
        enabled: true
      smb_mapping:
        enabled: true
      smtp:
        enabled: true
      snmp:
        enabled: true
      socks:
        enabled: true
      ssh:
        enabled: true
      ssl:
        enabled: true
      stats:
        enabled: true
      syslog:
        enabled: true
      traceroute:
        enabled: true
      tunnel:
        enabled: true
      weird:
        enabled: true
      x509:
        enabled: true

        # Set custom paths for the log files. If left empty,
        # Filebeat will choose the paths depending on your OS.
        #var.paths:
EOF

    #Start services
    sudo systemctl enable filebeat.service
    sudo systemctl start filebeat.service
    
    echo "[$(date +%H:%M:%S)]: ELK & FileBeats forwarding configuration complete."
}

cleanup(){
    #Deleting temp files
    rm -rf /tmp/setup_temp
}

main() {
    echo "------------\tKALI BOOTSTRAP RUNNING\t------------"
    
    #Installing
    echo "[$(date +%H:%M:%S)]: Setting Up RED Machine..."
    #install_filebeats
    echo "[$(date +%H:%M:%S)]: Installation Complete."
    
    #Configuring
    echo "[$(date +%H:%M:%S)]: Configuring RED Machine..."
    #configure_rsyslog
    #configure_zsh
    configure_filebeat
    echo "[$(date +%H:%M:%S)]: Configuration complete."
    
    #Cleanup
    echo "[$(date +%H:%M:%S)]: Cleaning Up..."
    #cleanup
    echo "[$(date +%H:%M:%S)]: Clean up complete."
    
    echo "------------\tKALI SETUP COMPLETE\t------------"
}

main
exit 0