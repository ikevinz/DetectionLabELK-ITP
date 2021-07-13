#! /usr/bin/env bash

# This is the script that is used to provision the kali host

install_filebeats() {
    # Install Filebeats
    echo "[$(date +%H:%M:%S)]: Installing Filebeats..."
    mkdir /tmp/setup_temp
    # cd /tmp/setup_temp
    # curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.13.0-amd64.deb
    # sudo dpkg -i filebeat-7.13.0-amd64.deb
    (cd /tmp/setup_temp && curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.13.0-amd64.deb && sudo dpkg -i filebeat-7.13.0-amd64.deb)
    echo "[$(date +%H:%M:%S)]: Filebeats Installed!"
}

install_auditbeat() {
    # Install Auditbeat
    echo "[$(date +%H:%M:%S)]: Installing Filebeats..."
    # cd /tmp/setup_temp
    # curl -L -O https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-7.13.1-amd64.deb
	# sudo dpkg -i auditbeat-7.13.1-amd64.deb
    (cd /tmp/setup_temp && curl -L -O https://artifacts.elastic.co/downloads/beats/auditbeat/auditbeat-7.13.1-amd64.deb && sudo dpkg -i auditbeat-7.13.1-amd64.deb)
    echo "[$(date +%H:%M:%S)]: Auditbeat Installed!"
}

install_zeek(){
    echo "[$(date +%H:%M:%S)]: Installing Zeek..."
    #Install Dependencies
    sudo apt update
    sudo apt -y install cmake make gcc g++ flex bison libpcap-dev libssl-dev python3 python3-dev swig zlib1g-dev
    
    #Clone Zeek Repo
    # cd /opt
    # git clone --recursive https://github.com/zeek/zeek
    (cd /opt && git clone --recursive https://github.com/zeek/zeek)

    #Install zeek
    # cd /opt/zeek
    # ./configure && make && sudo make install
    (cd /opt/zeek && ./configure && make && sudo make install)

    echo "[$(date +%H:%M:%S)]: Zeek Installed!"
}

configure_keylog(){
    echo "[$(date +%H:%M:%S)]: Installing Keylogger..."
	#mkdir /opt/RED_INSTRUMENTATION/keylogger
    # Keylog log file saved to /opt/RED_INSTRUMENTATION/keylogger/logs/keylogger.log
    # Configure 

    echo "[$(date +%H:%M:%S)]: Keylogger Installed!..."
}

configure_rsyslog() {
    # Configure rsyslog
    echo "[$(date +%H:%M:%S)]: Configuring rsyslog for shell command & keylogging collection..."
    
    # Creating rsyslog conf file
    # cd /etc/rsyslog.d
    # echo "local6.*  /var/log/zsh.log" > red.conf
    # echo "local7.*  /var/log/keylog.log" >> red.conf
    (cd /etc/rsyslog.d && echo "local6.*  /var/log/zsh.log" > red.conf && echo "local7.*  /var/log/keylog.log" >> red.conf)
    
    # Create the file under /var/log
    sudo touch /var/log/zsh.log
    sudo touch /var/log/keylog.log
    sudo systemctl restart rsyslog.service
    echo "[$(date +%H:%M:%S)]: Rsyslog configuration complete."
}

configure_zeek() {
    # Enable Zeek Filebeat Module
    sudo filebeat modules enable zeek

    export PATH=/usr/local/zeek/bin:$PATH

    # Config FIlebeat Zeek Module
    sudo tee /etc/filebeat/modules.d/zeek.yml <<EOF
    # Module: zeek
    # Docs: /guide/en/beats/filebeat/7.6/filebeat-module-zeek.html

    - module: zeek
        capture_loss:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/capture_loss.log"]
        connection:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/conn.log"]
        dce_rpc:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/dce_rpc.log"]
        dhcp:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/dhcp.log"]
        dnp3:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/dnp3.log"]
        dns:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/dns.log"]
        dpd:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/dpd.log"]
        files:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/files.log"]
        ftp:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/ftp.log"]
        http:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/http.log"]
        intel:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/intel.log"]
        irc:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/irc.log"]
        kerberos:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/kerberos.log"]
        modbus:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/modbus.log"]
        mysql:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/mysql.log"]
        notice:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/notice.log"]
        ntlm:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/ntlm.log"]
        ocsp:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/ocsp.log"]
        pe:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/pe.log"]
        radius:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/radius.log"]
        rdp:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/rdp.log"]
        rfb:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/rfb.log"]
        #  signatures:
        #    enabled: true
        #    var.paths: ["/usr/local/zeek/logs/current/signatures.log"]
        sip:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/sip.log"]
        smb_cmd:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/smb_cmd.log"]
        smb_files:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/smb_files.log"]
        smb_mapping:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/smb_mapping.log"]
        smtp:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/smtp.log"]
        snmp:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/snmp.log"]
        socks:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/socks.log"]
        ssh:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/ssh.log"]
        ssl:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/ssl.log"]
        stats:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/stats.log"]
        syslog:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/syslog.log"]
        traceroute:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/traceroute.log"]
        tunnel:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/tunnel.log"]
        weird:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/weird.log"]
        x509:
            enabled: true
            var.paths: ["/usr/local/zeek/logs/current/x509.log"]
EOF

    # Restart Filebeat
    sudo systemctl restart filebeat

    #Configure Zeek to output json
    echo '@load policy/tuning/json-logs.zeek
@load protocols/ftp/software
@load protocols/smtp/software
@load protocols/ssh/software
@load protocols/http/software
@load tuning/json-logs
@load policy/integration/collective-intel
@load policy/frameworks/intel/do_notice
@load frameworks/intel/seen
@load frameworks/intel/do_notice
@load frameworks/files/hash-all-files
@load base/protocols/smb
@load policy/protocols/conn/vlan-logging
@load policy/protocols/conn/mac-logging' | sudo tee -a /usr/local/zeek/share/zeek/site/local.zeek

    # Restart Zeek and Filebeat
    sudo /usr/local/zeek/bin/zeekctl deploy
    sudo systemctl restart filebeat
}

configure_zsh() {
    # Configure zsh
    echo "[$(date +%H:%M:%S)]: Configuring ZSH..."
    
    # Modifying the .zshrc file for Kali
    sed -i '/^setopt hist_verify/a setopt INC_APPEND_HISTORY\t# ZSH Config for Filebeats/ELK\n' ~/.zshrc
    sed -i "/^precmd() {/a    # Logging zsh commands to rsyslog\n    eval "'\x27RETRN_VAL=$?;logger -S 10000 -p local6.debug "{\\"user\\": \\"$(whoami)\\", \\"path\\": \\"$(pwd)\\", \\"pid\\": \\"$$\\", \\"b64_command\\": \\"$(history | tail -n1 | /usr/bin/sed "s/[ 0-9 ]*//" | base64 -w0 )\\", \\"status\\": \\"$RETRN_VAL\\"}"\x27' ~/.zshrc
    
    # Modifying root's zshrc
    sed -i '/^setopt hist_verify/a setopt INC_APPEND_HISTORY\t# ZSH Config for Filebeats/ELK\n' /root/.zshrc
    sed -i "/^precmd() {/a    # Logging zsh commands to rsyslog\n    eval "'\x27RETRN_VAL=$?;logger -S 10000 -p local6.debug "{\\"user\\": \\"$(whoami)\\", \\"path\\": \\"$(pwd)\\", \\"pid\\": \\"$$\\", \\"b64_command\\": \\"$(history | tail -n1 | /usr/bin/sed "s/[ 0-9 ]*//" | base64 -w0 )\\", \\"status\\": \\"$RETRN_VAL\\"}"\x27' /root/.zshrc
    
    # Modifying /etc/zsh/zshrc
	sed -i "$ aprecmd() {\n    # Logging zsh commands to rsyslog\n    eval "'\x27RETRN_VAL=$?;logger -S 10000 -p local6.debug "{\\"user\\": \\"$(whoami)\\", \\"path\\": \\"$(pwd)\\", \\"pid\\": \\"$$\\", \\"b64_command\\": \\"$(history | tail -n1 | /usr/bin/sed "s/[ 0-9 ]*//" | base64 -w0 )\\", \\"status\\": \\"$RETRN_VAL\\"}"\x27\n}' /etc/zsh/zshrc
    #cd /etc/zsh
    #sudo (echo $'\n'; echo >> zshrc
    # Reloading zsh
    # source ~/.zshrc
    
    echo "[$(date +%H:%M:%S)]: ZSH configuration complete."
}

configure_filebeat() {
    # Configure ELK Forwarding
    echo "[$(date +%H:%M:%S)]: Configuring ELK & FileBeats forwarding..."
    # sudo cp /vagrant/resources/kali/logstash.crt /etc/filebeat/
    sudo cp ./ELK/logstash.crt /etc/filebeat/
	sudo chmod 660 /etc/filebeat/logstash.crt
	
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
      enabled: true
      paths:
        - /var/log/zsh.log
      fields:
        infralogtype: zsh
      fields_under_root: true
    
    - type: log
      enabled: true
      paths:
        - /usr/local/zeek/logs/current/*.log
      fields:
        infralogtype: zeek
      fields_under_root: true
    
    - type: log
      enabled: true
      paths:
        - /var/log/keylogger.log
      fields:
        infralogtype: keylogger
      fields_under_root: true

    output.logstash:
      hosts: ["192.168.38.105:5045"]
      ssl.certificate_authorities: ["/etc/filebeat/logstash.crt"]

    logging:
      level: info
      to_files: true
      to_syslog: false
      files:
        path: /var/log/filebeat
        name: zsh-beat.log
        keepfiles: 2
EOF

    #Start services
    sudo systemctl enable filebeat.service
    sudo systemctl start filebeat.service
    
    echo "[$(date +%H:%M:%S)]: ELK & FileBeats forwarding configuration complete."
}

configure_auditbeat() {
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
}

cleanup(){
    #Deleting temp files
    rm -rf /tmp/setup_temp
}

main() {
    echo "------------  KALI BOOTSTRAP RUNNING  ------------"
    sudo timedatectl set-timezone Asia/Singapore
    #Installing
    echo "[$(date +%H:%M:%S)]: Setting Up RED Machine..."
    # mkdir /opt/RED_INSTRUMENTATION
    cp -aR ../RED_INSTRUMENTATION /opt/RED_INSTRUMENTATION
    install_filebeats
	install_auditbeat
    #install_zeek
    echo "[$(date +%H:%M:%S)]: Installation Complete."
    
    #Configuring
    echo "[$(date +%H:%M:%S)]: Configuring RED Machine..."
    configure_rsyslog
    configure_zsh
    configure_filebeat
    configure_zeek
	configure_auditbeat
    #configure_keylog
    echo "[$(date +%H:%M:%S)]: Configuration complete."
    
    #Cleanup
    echo "[$(date +%H:%M:%S)]: Cleaning Up..."
    cleanup
    echo "[$(date +%H:%M:%S)]: Clean up complete."
    
    echo "------------  KALI SETUP COMPLETE  ------------"
}
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

main
exit 0