#!/bin/bash -x
exec >/tmp/k3s-server-install-debug.log 2>&1

export INSTALL_K3S_NAME="${cluster_id}"
export K3S_TOKEN="${cluster_token}"
export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_SKIP_SELINUX_RPM=true  # Skip SELinux RPM during installation


# Check if this is the first master node or a subsequent one
if [ "${count.index}" == "0" ]; then
  # First master node initialization
  export ADDITIONAL_ARGS="--cluster-init"
  
  # Store the internal IP address of the first master node in SSM Parameter Store
  FIRST_MASTER_INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
  aws ssm put-parameter --name "/k3s/first-master-ip" --value "$FIRST_MASTER_INTERNAL_IP" --type String --overwrite
else
  # Subsequent master nodes
  # Retrieve the IP address of the first master node from SSM Parameter Store
  FIRST_MASTER_INTERNAL_IP=$(aws ssm get-parameter --name "/k3s/first-master-ip" --query "Parameter.Value" --output text)
  export ADDITIONAL_ARGS="--server=https://$FIRST_MASTER_INTERNAL_IP:6443"
fi

provider_id="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

curl -sfL https://get.k3s.io | sh -s - server \
	${ADDITIONAL_ARGS} \
	--disable-cloud-controller \
	--disable servicelb \
	--disable traefik \
	--node-name="$(hostname -f)" \
	--kubelet-arg="cloud-provider=external" \
	--kubelet-arg="provider-id=aws:///$${provider_id}"

unset INSTALL_K3S_NAME
unset K3S_TOKEN
unset K3S_KUBECONFIG_MODE
unset INSTALL_K3S_SKIP_SELINUX_RPM

echo "Installing Helm"
curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | sh

echo "Installing EBS CSI Driver chart..."
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm install aws-ebs-csi-driver \
	--kubeconfig /etc/rancher/k3s/k3s.yaml \
	--namespace kube-system \
	--set enableVolumeScheduling=true \
	--set enableVolumeResizing=true \
	--set enableVolumeSnapshot=true \
	--set cloud-provider=external \
	aws-ebs-csi-driver/aws-ebs-csi-driver

echo "K3s Setup Completed"
