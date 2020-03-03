#!/bin/bash
set -euo pipefail

rm -rf mydata/

docker run --rm -it -v $(PWD)/mydata/:/root --entrypoint bash cyberark/conjur-cli:5 -c "yes yes | conjur init -a $CONJUR_ACCOUNT -u $CONJUR_URL"
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 authn login -u admin -p $CONJUR_ADMIN_PASSWORD

cp -rf policy mydata/policy

docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 policy load root /root/policy/users.yml
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 policy load root /root/policy/app-id.yml
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 policy load root /root/policy/cluster-auth-svc.yml
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 policy load root /root/policy/app-identity-access-to-secrets.yml
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 policy load root /root/policy/app-access.yml

docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 variable values add cityapp-layer-app/db-username "<db username>"
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 variable values add cityapp-layer-app/db-password "<db password>"
