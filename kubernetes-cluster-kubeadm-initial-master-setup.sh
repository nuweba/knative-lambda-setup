# Install kubectl, kubeadm dependencies and set up cluster
sudo apt-get -y install kubectl socat ipvsadm < "/dev/null"
sudo kubeadm config images pull < "/dev/null"
cat >kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
apiServer:
  extraArgs:
    cloud-provider: aws
controllerManager:
  extraArgs:
    cloud-provider: aws
networking:
  podSubnet: 10.244.0.0/16
EOF
sudo kubeadm reset -f < "/dev/null"
sudo kubeadm init --config=kubeadm-config.yaml < "/dev/null"
mkdir -p $HOME/.kube
rm -f $HOME/.kube/config; sudo cp -f -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
rm -f kubeadm-config.yaml

# Wait for kube-system pods
EXPECTED_KUBE_SYSTEM_RUNNING_SERVICES=5
printf "Waiting for kubernetes base services.."; until [ $(kubectl get pods --namespace kube-system | grep --color=none "Running" | wc -l) == $EXPECTED_KUBE_SYSTEM_RUNNING_SERVICES ]; do printf "."; sleep 2s; done; echo " Done!"

# Set up pod networking
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Install basic kube2iam already configured for flannel pod networking subnet 
kubectl apply -f https://raw.githubusercontent.com/nuweba/knative-lambda-setup/master/kube2iam-basic-flannel-subnet.yaml