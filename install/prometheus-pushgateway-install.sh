#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/prometheus/pushgateway

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Prometheus Pushgateway"
RELEASE=$(curl -fsSL https://api.github.com/repos/prometheus/pushgateway/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir -p /etc/pushgateway
curl -fsSL "https://github.com/prometheus/pushgateway/releases/download/v${RELEASE}/pushgateway-${RELEASE}.linux-amd64.tar.gz" -o $(basename "https://github.com/prometheus/pushgateway/releases/download/v${RELEASE}/pushgateway-${RELEASE}.linux-amd64.tar.gz")
tar -xf pushgateway-"${RELEASE}".linux-amd64.tar.gz
mv pushgateway-"${RELEASE}".linux-amd64/pushgateway /usr/local/bin/
echo "${RELEASE}" >/opt/"${APPLICATION}"_version.txt
msg_ok "Installed Prometheus Pushgateway"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/pushgateway.service
[Unit]
Description=Prometheus Pushgateway
Wants=network-online.target
After=network-online.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=/usr/local/bin/pushgateway \
    --web.listen-address=0.0.0.0:9091 \
    --persistence.file=/etc/pushgateway/metrics.txt \
    --persistence.interval=5m
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now pushgateway
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
rm -rf pushgateway-"${RELEASE}".linux-amd64 pushgateway-"${RELEASE}".linux-amd64.tar.gz
msg_ok "Cleaned"
