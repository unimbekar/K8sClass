#!/bin/bash

# =================================================================
# EKS Worker Node Bootstrap Script
# =================================================================
# This script configures the worker node to join the EKS cluster
# with optimized settings for performance and security.

set -o xtrace

# =================================================================
# Variables (populated by Terraform)
# =================================================================
CLUSTER_NAME="${cluster_name}"
CLUSTER_ENDPOINT="${cluster_endpoint}"
CLUSTER_CA="${cluster_ca}"
BOOTSTRAP_ARGUMENTS="${bootstrap_arguments}"

# =================================================================
# System Updates and Optimization
# =================================================================
# Update the system packages
yum update -y

# Install additional useful packages
yum install -y \
    awscli \
    jq \
    wget \
    curl \
    htop \
    tree \
    vim

# =================================================================
# Container Runtime Optimization
# =================================================================
# Optimize containerd settings for better performance
cat > /etc/containerd/config.toml << 'EOF'
version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    enable_selinux = false
    sandbox_image = "602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/pause:3.5"
    
    [plugins."io.containerd.grpc.v1.cri".containerd]
      discard_unpacked_layers = true
      
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true

    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry-1.docker.io"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."public.ecr.aws"]
          endpoint = ["https://public.ecr.aws"]
EOF

# Restart containerd with new configuration
systemctl restart containerd

# =================================================================
# EKS Bootstrap
# =================================================================
# Join the node to the EKS cluster
/etc/eks/bootstrap.sh \
    $${CLUSTER_NAME} \
    --container-runtime containerd \
    --kubelet-extra-args "--node-labels=environment=${var.environment},nodegroup-type=main-nodes" \
    $${BOOTSTRAP_ARGUMENTS}

# =================================================================
# CloudWatch Agent Configuration (Optional)
# =================================================================
# Install CloudWatch agent for enhanced monitoring
# Uncomment the following lines if you want detailed node monitoring

# yum install -y amazon-cloudwatch-agent
# cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
# {
#   "agent": {
#     "metrics_collection_interval": 60,
#     "run_as_user": "cwagent"
#   },
#   "metrics": {
#     "namespace": "EKS/NodeMetrics",
#     "metrics_collected": {
#       "cpu": {
#         "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
#         "metrics_collection_interval": 60
#       },
#       "disk": {
#         "measurement": ["used_percent"],
#         "metrics_collection_interval": 60,
#         "resources": ["*"]
#       },
#       "diskio": {
#         "measurement": ["io_time"],
#         "metrics_collection_interval": 60,
#         "resources": ["*"]
#       },
#       "mem": {
#         "measurement": ["mem_used_percent"],
#         "metrics_collection_interval": 60
#       }
#     }
#   }
# }
# EOF

# /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#     -a fetch-config \
#     -m ec2 \
#     -s \
#     -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# =================================================================
# Security Hardening
# =================================================================
# Configure system limits for container workloads
cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF

# Configure kernel parameters for container networking
cat >> /etc/sysctl.conf << 'EOF'
# Container networking optimizations
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1

# Network performance tuning
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_syn_backlog = 8192

# Memory management
vm.max_map_count = 262144
EOF

# Apply sysctl settings
sysctl -p

# =================================================================
# Logging Configuration
# =================================================================
# Configure log rotation for container logs
cat > /etc/logrotate.d/kubernetes << 'EOF'
/var/log/pods/*/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    copytruncate
    create 0644 root root
}
EOF

# =================================================================
# Node Readiness Check
# =================================================================
# Wait for the node to be ready and joined to the cluster
echo "Waiting for node to join cluster..."
until kubectl --kubeconfig=/var/lib/kubelet/kubeconfig get nodes $$(hostname -f) &>/dev/null; do
    echo "Node not yet joined to cluster, waiting..."
    sleep 30
done

echo "Node successfully joined cluster: $${CLUSTER_NAME}"
echo "Bootstrap completed at: $$(date)"

# =================================================================
# Custom Application Setup (Optional)
# =================================================================
# Add any custom application setup here
# For example: install monitoring agents, security tools, etc.

# Example: Install Node Exporter for Prometheus monitoring
# wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
# tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
# cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
# chown root:root /usr/local/bin/node_exporter

# Create systemd service for node_exporter
# cat > /etc/systemd/system/node_exporter.service << 'EOF'
# [Unit]
# Description=Node Exporter
# Wants=network-online.target
# After=network-online.target

# [Service]
# User=nobody
# ExecStart=/usr/local/bin/node_exporter
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target
# EOF

# systemctl daemon-reload
# systemctl enable node_exporter
# systemctl start node_exporter

echo "==================================================================="
echo "EKS Worker Node Bootstrap Complete"
echo "Cluster: $${CLUSTER_NAME}"
echo "Node: $$(hostname -f)"
echo "Timestamp: $$(date)"
echo "==================================================================="