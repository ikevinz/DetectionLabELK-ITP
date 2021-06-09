#!/bin/bash

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
echo "deb [arch=amd64] https://packages.elastic.co/curator/5/debian stable main" | sudo tee -a /etc/apt/sources.list.d/curator-5.list
apt-get -qq update
apt-get -qq install default-jre
apt-get -qq install elasticsearch -y # 1st install elasticseatch to get JDK
export JAVA_HOME=/usr/share/elasticsearch/jdk && echo export JAVA_HOME=/usr/share/elasticsearch/jdk >>/etc/bash.bashrc
apt-get -qq install kibana filebeat auditbeat elasticsearch-curator logstash -y

cat >/etc/cron.daily/curator <<EOF
#!/bin/sh
curator_cli --host 192.168.38.105 delete_indices --filter_list '{"filtertype": "age", "source": "name", "timestring": "%Y.%m.%d", "unit": "days", "unit_count": 1, "direction": "older"}'  > /dev/null 2>&1
EOF
chmod +x /etc/cron.daily/curator

printf vagrant | /usr/share/elasticsearch/bin/elasticsearch-keystore add -x "bootstrap.password" -f
/usr/share/elasticsearch/bin/elasticsearch-users useradd vagrant -p vagrant -r superuser

# Elasticsearch CA cert generation:
sudo mkdir /etc/elasticsearch/certs
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca --days 1095 --keysize 4096 --pass 's3cur3P@ssw0rd!@#' --out /etc/elasticsearch/certs/elastic-ca.p12
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca /etc/elasticsearch/certs/elastic-ca.p12 --ca-pass 's3cur3P@ssw0rd!@#' --pass "" --out /etc/elasticsearch/certs/elastic-certificates.p12
sudo chmod 660 /etc/elasticsearch/certs/elastic-ca.p12
sudo chmod 660 /etc/elasticsearch/certs/elastic-certificates.p12

# Kibana https configuration:
sudo mkdir /etc/kibana/certs
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --pem --ca /etc/elasticsearch/certs/elastic-ca.p12 --ca-pass 's3cur3P@ssw0rd!@#' --out /etc/kibana/certs/kibana-ssl.zip
sudo unzip /etc/kibana/certs/kibana-ssl.zip -d /etc/kibana/certs/
sudo chmod 660 /etc/kibana/certs/instance/instance.crt
sudo chmod 660 /etc/kibana/certs/instance/instance.key

# Logstash https configuration:
sudo chown -R logstash:logstash /etc/logstash/
sudo mkdir /etc/logstash/certs/
sudo openssl pkcs12 -in /etc/elasticsearch/certs/elastic-certificates.p12 -out /etc/logstash/certs/logstash.pem -clcerts -nokeys -passin pass:
sudo openssl pkcs12 -in /etc/elasticsearch/certs/elastic-certificates.p12 -nocerts -nodes -passin pass: | sudo sed -ne '/-BEGIN PRIVATE KEY-/,/-END PRIVATE KEY-/p' > logstash-ca.key && sudo mv logstash-ca.key /etc/logstash/certs/logstash-ca.key
sudo openssl pkcs12 -in /etc/elasticsearch/certs/elastic-certificates.p12 -cacerts -nokeys -chain -passin pass: | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > logstash-ca.crt && sudo mv logstash-ca.crt /etc/logstash/certs/logstash-ca.crt
sudo openssl pkcs12 -in /etc/elasticsearch/certs/elastic-certificates.p12 -clcerts -nokeys -passin pass: | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > logstash.crt && sudo mv logstash.crt /etc/logstash/certs/logstash.crt
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca-cert /etc/logstash/certs/logstash-ca.crt --ca-key /etc/logstash/certs/logstash-ca.key --pem --out /etc/logstash/certs/logstash-ssl.zip
sudo unzip /etc/logstash/certs/logstash-ssl.zip -d /etc/logstash/certs/
sudo openssl pkcs8 -in /etc/logstash/certs/instance/instance.key -topk8 -nocrypt -out /etc/logstash/certs/logstash.pkcs8.key
sudo chown -R logstash:logstash /etc/logstash/
sudo chmod 660 /etc/logstash/certs/instance/instance.crt
sudo chmod 660 /etc/logstash/certs/instance/instance.key
sudo chmod 660 /etc/logstash/certs/logstash-ca.crt
sudo chmod 660 /etc/logstash/certs/logstash-ca.key
sudo chmod 660 /etc/logstash/certs/logstash.crt
sudo chmod 660 /etc/logstash/certs/logstash.pem
sudo chmod 660 /etc/logstash/certs/logstash.pkcs8.key

cat >/etc/elasticsearch/elasticsearch.yml <<EOF
network.host: _eth1:ipv4_
discovery.type: single-node
cluster.name: cydef-es-cluster
node.name: \${HOSTNAME}
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
xpack.security.enabled: true
xpack.security.authc:
        api_key.enabled: true
        anonymous:
                username: anonymous
                roles: superuser
                authz_exception: false
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.truststore.path: certs/elastic-certificates.p12
xpack.security.http.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.http.ssl.verification_mode: certificate
EOF

cat >/etc/default/elasticsearch <<EOF
ES_PATH_CONF=/etc/elasticsearch
ES_STARTUP_SLEEP_TIME=5
MAX_OPEN_FILES=65536
MAX_LOCKED_MEMORY=unlimited
EOF

mkdir /etc/systemd/system/elasticsearch.service.d/
cat >/etc/systemd/system/elasticsearch.service.d/override.conf <<EOF
[Service]
LimitMEMLOCK=infinity
EOF

cat >/etc/security/limits.conf <<EOF
elasticsearch soft nofile 65536
elasticsearch hard nofile 65536
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF

#Changing elasticsearch jvm options:
#Set RAM usage as 1GB max
sudo sed -i 's/## -Xms4g/-Xms1g/g' /etc/elasticsearch/jvm.options
sudo sed -i 's/## -Xmx4g/-Xmx1g/g' /etc/elasticsearch/jvm.options

/bin/systemctl daemon-reload
/bin/systemctl enable elasticsearch.service
/bin/systemctl start elasticsearch.service

#logstash
cat >/etc/logstash/logstash.yml <<EOF
pipeline:
  batch:
    size: 125
    delay: 5
path.data: /var/lib/logstash
pipeline.ordered: auto
path.config: /etc/logstash/conf.d/
config.reload.automatic: true
path.logs: /var/log/logstash
xpack.monitoring.elasticsearch.ssl.certificate_authority: /etc/logstash/certs/logstash-ca.crt
xpack.monitoring.elasticsearch.sniffing: true
xpack.monitoring.collection.interval: 10s
xpack.monitoring.collection.pipeline.details.enabled: true
EOF

sudo touch /etc/logstash/conf.d/zsh.conf
cat > /etc/logstash/conf.d/zsh.conf <<EOF
input {
    beats {
        port => 5045
        host => "192.168.38.105"
        ssl => true
        ssl_certificate => "/etc/logstash/certs/instance/instance.crt"
        ssl_key => "/etc/logstash/certs/logstash.pkcs8.key"
    }
}

filter {
  if [infralogtype] == "zsh" {
    grok {
      match => { "message" => "^%{SYSLOGTIMESTAMP:syslog_timestamp}\s%{HOSTNAME}\s.+?:\s(?<json_message>.*)$"}
      add_field => [ "received_at", "%{@timestamp}" ]
    }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
    json {
      source => "json_message"
    }
    ruby {
      init => "require 'base64'"
      code => 'event.set("[command]", event.get("b64_command") ? Base64.decode64(event.get("b64_command")) : nil)'
    }
  }
}

output {
  if [infralogtype] == "zsh" {
    elasticsearch{
      hosts => ["192.168.38.105:9200"]
      sniffing => true
      index => "zsh-%{+YYYY.MM.dd}"
      ssl => true
      ssl_certificate_verification => false
      cacert => '/etc/logstash/certs/logstash.pem'
    }
  }
}
EOF

sudo chown -R logstash:logstash /etc/logstash/
/bin/systemctl enable logstash.service
/bin/systemctl start logstash.service

#kibana
touch /var/log/kibana.log
chown kibana:kibana /var/log/kibana.log
cat >/etc/kibana/kibana.yml <<EOF
server.host: "192.168.38.105"
elasticsearch.hosts: ["https://192.168.38.105:9200"]
elasticsearch.ssl.verificationMode: none
logging.dest: "/var/log/kibana.log"
kibana.defaultAppId: "discover"
telemetry.enabled: false
telemetry.optIn: false
newsfeed.enabled: false
xpack.security.enabled: true
xpack.ingestManager.fleet.tlsCheckDisabled: true
xpack.encryptedSavedObjects.encryptionKey: 'fhjskloppd678ehkdfdlliverpoolfcr'
server.ssl.enabled: true
server.ssl.certificate: "/etc/kibana/certs/instance/instance.crt"
server.ssl.key: "/etc/kibana/certs/instance/instance.key"
EOF

/bin/systemctl enable kibana.service
/bin/systemctl start kibana.service

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

mkdir /var/log/bro/
ln -s /opt/zeek/logs/current/ /var/log/bro/current
filebeat --path.config /etc/filebeat modules enable zeek

filebeat --path.config /etc/filebeat modules enable suricata

# make sure kibana is up and running
echo "Waiting for Kibana to be up..."
while true; do
  result=$(curl -uvagrant:vagrant --silent --insecure https://192.168.38.105:5601/api/status)
  if echo $result | grep -q logger; then break; fi
  sleep 1
done

/bin/systemctl enable filebeat.service
/bin/systemctl start filebeat.service

/bin/systemctl enable auditbeat.service
/bin/systemctl start auditbeat.service

# Export logstash cert
sudo cp /etc/logstash/certs/instance/instance.crt /vagrant/resources/kali/logstash.crt

# load SIEM prebuilt rules
echo "Load SIEM prebuilt rules"
sleep 60
curl -s -uvagrant:vagrant --insecure -XPOST "https://192.168.38.105:5601/api/detection_engine/index" -H 'kbn-xsrf: true' -H 'Content-Type: application/json'
sleep 1
curl -s -uvagrant:vagrant --insecure -XPUT "https://192.168.38.105:5601/api/detection_engine/rules/prepackaged" -H 'kbn-xsrf: true' -H 'Content-Type: application/json'

# Enable elasticsearch trial
# echo "Enable elastic trial version"
# curl -s -XPOST "192.168.38.105:9200/_license/start_trial?acknowledge=true&pretty"
