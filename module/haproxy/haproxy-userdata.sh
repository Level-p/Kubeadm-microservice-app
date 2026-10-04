#!/bin/bash
# Update system and install HAProxy
apt-get update -y
apt-get install --no-install-recommends software-properties-common -y
apt-get install haproxy -y

# Configure HAProxy
sudo bash -c 'cat <<EOT > /etc/haproxy/haproxy.cfg
frontend fe-apiserver
    bind 0.0.0.0:6443
    mode tcp
    option tcplog
    default_backend be-apiserver

backend be-apiserver
    balance roundrobin
    mode tcp
    option tcplog
    option tcp-check
    server master1 ${master1}:6443 check
    server master2 ${master2}:6443 check
    server master3 ${master3}:6443 check
EOT'
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY="${nr_key}" NEW_RELIC_ACCOUNT_ID="${nr_acc_id}" NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y
# Enable HAProxy to start on boot
systemctl restart haproxy
systemctl enable haproxy
