#!/bin/bash
set -euo pipefail


echo "Creating Test App namespace."

if ! kubectl get namespace $TEST_APP_NAMESPACE_NAME > /dev/null
then
    kubectl create namespace $TEST_APP_NAMESPACE_NAME
fi

kubectl config set-context $(kubectl config current-context) --namespace=$TEST_APP_NAMESPACE_NAME

echo "Adding Role Binding for conjur service account"

kubectl delete rolebinding conjur-authenticator-role-binding

kubectl create -f ./cityapp-conjur-authenticator-role-binding.yml

echo "Storing non-secret conjur cert as test app configuration data"

kubectl delete --ignore-not-found=true configmap conjur-cert

cp mydata/*.pem .
# Store the Conjur cert in a ConfigMap.
kubectl create configmap conjur-cert --from-file=ssl-certificate=./conjur-$CONJUR_ACCOUNT.pem

echo "Conjur cert stored."

test_app_image=asia.gcr.io/<project name>/cityapp-summon:1.0
echo "Deploying test app FrontEnd"

conjur_authenticator_url=$CONJUR_URL/authn-k8s/$AUTHENTICATOR_ID

sed -e "s#{{ TEST_APP_DOCKER_IMAGE }}#$test_app_image#g" ./cityapp-conjur.yml |
  sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
  sed -e "s#{{ CONJUR_APPLIANCE_URL }}#$CONJUR_URL#g" |
  sed -e "s#{{ CONJUR_AUTHN_URL }}#$conjur_authenticator_url#g" |
  kubectl create -f -


echo "Waiting for services to become available"
while [ -z "$(kubectl describe service cityapp-sidecar | grep 'LoadBalancer Ingress' | awk '{ print $3 }')" ]; do
    printf "."
    sleep 1
done

kubectl describe service cityapp-sidecar | grep 'LoadBalancer Ingress'

app_url=$(kubectl describe service cityapp-sidecar | grep 'LoadBalancer Ingress' | awk '{ print $3 }'):3000

curl -k $app_url
