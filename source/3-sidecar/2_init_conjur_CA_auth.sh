

## inicializa CA y almacena llaves en conjur

cp startCA.sh mydata/startCA.sh

#docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 authn login -u admin -p $CONJUR_ADMIN_PASSWORD
docker run --rm -it -v $(PWD)/mydata/:/root -e AUTHENTICATOR_ID -e CONJUR_ACCOUNT  \
        --entrypoint bash cyberark/conjur-cli:5 /root/startCA.sh

