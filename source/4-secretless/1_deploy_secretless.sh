source bootstrap.env

kubectl \
  --namespace cityapp \
  create configmap \
  cityapp-secretless-config \
  --from-file=secretless.yml

export test_app_image=asia.gcr.io/cityapp:1.0


sed -e "s#{{ TEST_APP_DOCKER_IMAGE }}#$test_app_image#g" ./cityapp-secretless.yml |
  sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" |
  sed -e "s#{{ CONJUR_APPLIANCE_URL }}#$CONJUR_URL#g" |
  sed -e "s#{{ CONJUR_AUTHN_URL }}#$conjur_authenticator_url#g" |
  kubectl create -f -
