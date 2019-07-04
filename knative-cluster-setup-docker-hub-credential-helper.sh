## REPLACE THOSE FIRST 2 PARAMETERS WITH YOUR DOCKER HUB USERNAME AND PASSWORD
DOCKERHUB_USER=replaceme
DOCKERHUB_PASS=replaceme
B64USER=$(echo -n $DOCKERHUB_USER | base64); B64PASS=$(echo -n $DOCKERHUB_PASS | base64); 
curl -fsS https://raw.githubusercontent.com/nuweba/knative-lambda-setup/master/knative-docker-hub-credentials-template.yaml | sed -e "s/REPLACE_WITH_YOUR_BASE64_USERNAME/$B64USER/g; s/REPLACE_WITH_YOUR_BASE64_PASSWORD/$B64PASS/g" | kubectl apply -f -