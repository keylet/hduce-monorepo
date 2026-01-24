#!/bin/bash
# ============================================
# INSTANCE 0: BASTION HOST - MINIMAL SETUP
# HDuce Medical Platform - AWS Academy
# ============================================

set -e  # Exit on error
echo "🛡️ Starting Bastion Host setup..."

# Update system
sudo yum update -y
sudo yum install -y git curl wget unzip net-tools

# Install useful tools for debugging
echo "🔧 Installing useful tools..."
sudo yum install -y htop ncdu tmux jq

# Configure SSH to allow agent forwarding
echo "🔐 Configuring SSH for Jump Host..."
sudo sed -i 's/#AllowAgentForwarding yes/AllowAgentForwarding yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Create directory for SSH keys (optional)
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create helpful aliases
echo "📝 Creating helpful aliases..."
cat >> ~/.bashrc << 'EOF'
# HDuce Bastion Aliases
alias hduce-status='echo "Bastion Host ready for HDuce deployment"'
alias list-instances='aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,IP:PrivateIpAddress,State:State.Name}" --output table'
alias my-ip='curl -s http://checkip.amazonaws.com'
EOF

source ~/.bashrc

echo "✅ Bastion Host setup complete!"
echo "📋 Next steps:"
echo "   1. SSH to this bastion: ssh -i key.pem ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "   2. From bastion, SSH to internal instances using their private IPs"
echo "   3. Deploy HDuce services using deployment scripts"
