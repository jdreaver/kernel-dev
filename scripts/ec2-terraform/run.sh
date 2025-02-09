#!/usr/bin/env bash

set -euo pipefail

# cd into script directory
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$script_dir"

# Initialize Terraform if needed
terraform_bin=./terraform
if [ ! -f "$terraform_bin" ]; then
    echo "Downloading terraform..."
    curl -s -L https://releases.hashicorp.com/terraform/1.10.5/terraform_1.10.5_darwin_arm64.zip -o terraform.zip
    mkdir terraform-zip
    unzip terraform.zip -d terraform-zip
    mv terraform-zip/terraform .
    rm -rf terraform-zip terraform.zip
fi

if [ ! -f .terraform.lock.hcl ]; then
    echo "Initializing terraform"
    "$terraform_bin" init
fi

echo "Fetching public IP..."
public_ip=$(curl -s https://api.ipify.org)
echo "Public IP: $public_ip"

# Populate terraform.tfvars file
cat > terraform.tfvars <<EOF
user = "$USER"
public_ip = "$public_ip"
EOF

# Populate overrides file if it doesn't exist
if [ ! -f overrides.auto.tfvars ]; then
  cat > overrides.auto.tfvars <<EOF
# instance_type = "m6i.4xlarge"
# instance_state = "stopped"
EOF
fi

exec "$terraform_bin" "$@"
