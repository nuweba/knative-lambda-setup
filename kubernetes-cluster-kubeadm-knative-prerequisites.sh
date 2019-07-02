# Fix EC2 Hostname
curl 169.254.169.254/latest/meta-data/hostname
echo 127.0.0.1 $(curl 169.254.169.254/latest/meta-data/hostname) | sudo tee -a /etc/hosts
curl 169.254.169.254/latest/meta-data/hostname | sudo tee /etc/hostname
sudo hostname $(curl 169.254.169.254/latest/meta-data/hostname)

# Get & Configure Docker
export DEBIAN_FRONTEND=noninteractive
sudo resize2fs -f /dev/xvda1 < "/dev/null"
sudo growpart /dev/xvda 1 < "/dev/null"
sudo apt-get update < "/dev/null"
sudo apt-get -o Dpkg::Options::="--force-confold" --allow-remove-essential -y upgrade < "/dev/null"
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common < "/dev/null"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
sudo apt-get -y remove docker docker-engine docker.io containerd runc < "/dev/null"
sudo apt-get -y update < "/dev/null"
sudo apt-get -y install docker-ce=18.06.2~ce~3-0~ubuntu < "/dev/null"
sudo sh -c 'cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF'
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker 

# Get & Configure Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo sh -c 'cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF'
sudo apt-get -y update < "/dev/null"
sudo sh -c "echo 'KUBELET_EXTRA_ARGS=\"--cgroup-driver=systemd --cloud-provider=aws\"' > /etc/default/kubelet"
sudo apt-get -y install kubelet kubeadm awscli jq < "/dev/null"
aws --region $(ec2metadata --availability-zone | rev | cut -c 2- | rev) ec2 create-tags --resources $(ec2metadata --instance-id) --tags "Key=kubernetes.io/cluster/knative-playground,Value=nuweba"
sudo sysctl net.bridge.bridge-nf-call-iptables=1