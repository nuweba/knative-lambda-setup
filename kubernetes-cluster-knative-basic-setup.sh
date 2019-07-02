#!/bin/bash

#### KNATIVE TIME!
kubectl label namespace default istio-injection=enabled < "/dev/null" 2>/dev/null
kubectl label nodes --all beta.kubernetes.io/fluentd-ds-ready="true" < "/dev/null" 2>/dev/null

# Install Istio as our main ingress-egress gateway
kubectl apply -f https://github.com/knative/serving/releases/download/v0.5.2/istio-crds.yaml < "/dev/null"
kubectl apply -f https://github.com/knative/serving/releases/download/v0.5.2/istio.yaml < "/dev/null"

EXPECTED_ISTIO_RUNNING_SERVICES=11
# Could have use the alias in this waiter, but want to avoid cases where people don't copy paste everything I guess? 
printf "Waiting for Istio services to move to Running status.."; until [ $(kubectl get pods --namespace istio-system | grep --color=none "Running" | wc -l) == $EXPECTED_ISTIO_RUNNING_SERVICES ]; do printf "."; sleep 2s; done; echo " Done!"

# Install Knative necessary services (with basic monitoring, but without tracing, advanced eventing etc.)
KNATIVE_SERVING=https://github.com/knative/serving/releases/download/v0.5.2/serving.yaml
KNATIVE_BUILD=https://github.com/knative/build/releases/download/v0.5.0/build.yaml
KNATIVE_EVENTING=https://github.com/knative/eventing/releases/download/v0.5.0/release.yaml
KNATIVE_EVENTING_IN_MEM=https://github.com/knative/eventing/releases/download/v0.5.0/in-memory-channel.yaml
KNATIVE_EVENTING_SOURCES=https://github.com/knative/eventing-sources/releases/download/v0.5.0/eventing-sources.yaml
KNATIVE_CLUSTERROLE=https://raw.githubusercontent.com/knative/serving/v0.5.2/third_party/config/build/clusterrole.yaml

(kubectl delete -f $KNATIVE_SERVING; kubectl delete -f $KNATIVE_BUILD; kubectl delete -f $KNATIVE_EVENTING; kubectl delete -f $KNATIVE_EVENTING_SOURCES; kubectl delete -f $KNATIVE_CLUSTERROLE;) 2>/dev/null 
kubectl apply --selector knative.dev/crd-install=true --filename $KNATIVE_SERVING --filename $KNATIVE_BUILD --filename $KNATIVE_EVENTING --filename $KNATIVE_EVENTING_SOURCES --filename $KNATIVE_CLUSTERROLE < "/dev/null" 2>/dev/null 
kubectl apply --filename $KNATIVE_SERVING --filename $KNATIVE_BUILD --filename $KNATIVE_EVENTING --filename $KNATIVE_EVENTING_SOURCES --filename $KNATIVE_CLUSTERROLE < "/dev/null" 2>/dev/null 

# Worked as an alias named 'kctl_gpfn' but sadly enough it is only expanded in an interactive shell, so moved back to a very long command line
EXPECTED_KNATIVE_RUNNING_SERVICES=11
printf "Waiting for Knative services to move to Running status.."; until [ $({ kubectl get pods --namespace knative-build & kubectl get pods --namespace knative-eventing & kubectl get pods --namespace knative-serving & kubectl get pods --namespace knative-sources; } | grep --color=none "Running" | wc -l) == $EXPECTED_KNATIVE_RUNNING_SERVICES ]; do printf "."; sleep 2s; done; echo " Done!"

# Set Knative's custom domain to use ours and open up egress traffic before installing Istio
kubectl apply -f https://raw.githubusercontent.com/nuweba/knative-lambda-setup/master/knative-custom-domain-and-istio-egress-rules.yaml