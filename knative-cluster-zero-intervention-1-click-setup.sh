# Assumes you have already configured 2 x EC2 Instances as master and node with the correct
# permissions, security groups, etc.
# CLUSTER CONFIGURATION: Change the environment variables to reflect your setup 
MASTER_PUBLIC_IP_OR_DNS=ec2-XX-XX-XX-XX.us-west-1.compute.amazonaws.com
NODE_PUBLIC_IP_OR_DNS=ec2-XX-XX-XX-XX.us-west-1.compute.amazonaws.com
CLUSTER_INSTANCES_SSH_PRIVATE_KEY_PATH=knative-playground-keypair.pem.txt
CLUSTER_INSTANCES_LINUX_USER=ubuntu

# Add public keys to known_hosts so no prompt comes up on next commands
ssh-keyscan -H $MASTER_PUBLIC_IP_OR_DNS >> ~/.ssh/known_hosts
ssh-keyscan -H $NODE_PUBLIC_IP_OR_DNS >> ~/.ssh/known_hosts

# Perform shared generic setup stage
for host in $MASTER_PUBLIC_IP_OR_DNS $NODE_PUBLIC_IP_OR_DNS; do (echo "Executing prerequisites installation on $host:" && (ssh -i $CLUSTER_INSTANCES_SSH_PRIVATE_KEY_PATH $CLUSTER_INSTANCES_LINUX_USER@$host set pipefail \; curl -fsS https://raw.githubusercontent.com/nuweba/knative-lambda-setup/master/kubernetes-cluster-kubeadm-knative-prerequisites.sh \| bash)) 2>/dev/null ; done

# Perform master setup script and get the kubeadm join token, assuming kubeadm is a 2-line output
echo "Setting up kubeadm on master and saving it's join token.." && ((ssh -i $CLUSTER_INSTANCES_SSH_PRIVATE_KEY_PATH $CLUSTER_INSTANCES_LINUX_USER@$MASTER_PUBLIC_IP_OR_DNS set pipefail \; curl -fsS https://raw.githubusercontent.com/nuweba/knative-lambda-setup/master/kubernetes-cluster-kubeadm-initial-master-setup.sh \| bash) 2>/dev/null) | tee /tmp/cluster-setup-output
KUBEADM_JOIN_COMMAND=$(cat /tmp/cluster-setup-output | grep -A 1 "kubeadm join " | sed -e 's/^[ \t]*//')
rm -f /tmp/cluster-setup-output

# Join node by executing command output
echo "Joining the cluster from the node instance.."
(ssh -i $CLUSTER_INSTANCES_SSH_PRIVATE_KEY_PATH $CLUSTER_INSTANCES_LINUX_USER@$NODE_PUBLIC_IP_OR_DNS echo "Stopping kubelet and joining Kubernetes cluster on node by executing '$KUBEADM_JOIN_COMMAND'" \&\& sudo systemctl stop kubelet \&\& sudo kubeadm reset -f \&\& echo "\"sudo $KUBEADM_JOIN_COMMAND\"" \> /tmp/join.sh \&\& chmod +x /tmp/join.sh \&\& sudo /tmp/join.sh \&\& sudo rm -f /tmp/join.sh) 2>/dev/null

# Install Knative components on master
echo "Going back to master to install Knative components.."
(ssh -i $CLUSTER_INSTANCES_SSH_PRIVATE_KEY_PATH $CLUSTER_INSTANCES_LINUX_USER@$MASTER_PUBLIC_IP_OR_DNS set pipefail \; curl -fsS https://raw.githubusercontent.com/nuweba/knative-lambda-setup/master/kubernetes-cluster-knative-basic-setup.sh \| bash) 2>/dev/null