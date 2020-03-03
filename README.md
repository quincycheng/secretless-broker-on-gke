# Secretless Broker Demo on GKE

This repo contains scripts and files for deploying secretless broker demo on GKE with Istio enabled
```
Note: This repo contains sensitive info, like hardcoded passwords and IP, 
      intentionally for demostration purpose. 
      None of them are real and all of them do not work.
```

![secretless](https://github.com/quincycheng/secretless-broker-on-gke/raw/master/images/secretless_sg_ntuc%20v0.1.png)


# Prepare the environment

## What you will need
 - GCP accounts, with billing activited
 - This repo, files & scripts are under `source` folder
 - Sample world database from MySQL, can be downloaded at https://dev.mysql.com/doc/index-other.html
 - 7 avaliable `in-use IP address global` quota from GCP, check `IAM & Admin` > `Quotas` section
 - Docker client & local registry (included by default Docker server installation)


## Build a k8s cluster
1. Login to https://cloud.google.com
2. Visit the Kubernetes Engine page in the Google Cloud Console.
3. Install `gcloud` & `kubectl` clients
   https://cloud.google.com/sdk/docs/quickstarts
4. Deploy GKE with Istio 
   https://cloud.google.com/istio/docs/istio-on-gke/installing#creating_a_cluster_with_istio_on_gke
5. Install Helm client 
   https://helm.sh/docs/using_helm/#installing-helm
6. Enable Helm on GKE if it is not enabled

## Install Cloud SQL database
1. Create a new database instance based on MySQL
2. Import the world sample database
3. Create a new user that can access & read the world database
4. Make sure the k8s cluster are allowed to access this database, configured in `Connections` section


## Setup kubectl
```
gcloud container clusters get-credentials <cluster name> --region <region, e.g. asia-east2-c>
```


# Setup Conjur
Note: you can use DAP as well


1. Install Conjur OSS  
```
helm install conjur cyberark/conjur-oss \
--set ssl.hostname=<conjur fqdn>,dataKey="$(docker run --rm cyberark/conjur data-key generate)",authenticators="authn-k8s/dev\,authn" \
 --namespace "conjur"
```
8. Wait for external ip and update the DNS host record
```
kubectl get svc -w conjur-conjur-oss-ingress -n conjur
```
9. Create an account and get admin password
```
export POD_NAME=$(kubectl get pods --namespace conjur \
               -l "app=conjur-oss" \
               -o jsonpath="{.items[0].metadata.name}")

# Set Admin Password
kubectl exec $POD_NAME --container=conjur-oss --namespace conjur conjurctl account create default
```
10. Change the admin password
```
docker run --rm -it -v $(PWD)/mydata/:/root --entrypoint bash cyberark/conjur-cli:5 -c "yes yes | conjur init -a default -u https://<conjur fqdn>"
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 authn login -u admin -p <generated admin password>
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 user update_password -p <new password>
docker run --rm -it -v $(PWD)/mydata/:/root cyberark/conjur-cli:5 authn logout
```

# Application

## Preparing the container images

1. In `app\orginal`, execute:
```
sudo docker build -t cityapp:1.0 .
docker tag cityapp:1.0 asia.gcr.io/<project name>/cityapp:1.0
docker push asia.gcr.io/<project name>/cityapp:1.0
```

2.  In `app\with_summon` folder, execute:
```
sudo docker build -t cityapp_summon:1.0 .
docker tag cityapp_summon:1.0 asia.gcr.io/<project name>/cityapp-summon:1.0
docker push asia.gcr.io/<project name>/cityapp-summon:1.0
```


## Cityapp Hard Code App
In the `1-hardcode` folder, update `cityapp-hardcode.yaml` and execute:
```
kubectl apply -f cityapp-hardcode.yaml -n cityapp
```


## Cityapp k8s secrets App
In the `2-k8s-secrets` folder, update `cityapp-k8s-secret.yam` and lexecute:
```
kubectl create secret generic mysql01-secret --from-literal=password=<db password>
kubectl apply -n cityapp  -f 2-k8s-secret/cityapp-k8s-secret.yaml
```


## Cityapp sidecar & secretless app

This section are based on the following references:
 - https://docs.conjur.org/Latest/en/Content/Integrations/Kubernetes_deployApplicationCluster.htm
 - https://docs.conjur.org/Latest/en/Content/Integrations/Kubernetes_deployAuthenticatorSidecar.htm

1. Go to `3-sidecar` folder.
2. Update `bootstrap.env`
3. Review all `*.sh` and make necessary updates, like `<conjur fqdn>` or `db password`
4. Review the policy files under `policy` folder
5. Execute `1-load_conjur_policies.sh` to import the policies
6. Execute `2_init_conjur_CA_auth.sh` to import the CA for k8s authn
7. Execute `3_deploy_testapp_with_conjur.sh` to deploy the test application with sidecar & summon

### Cityapp Secretless app
This section make use of the following references:
- https://docs.conjur.org/Latest/en/Content/Get%20Started/scl_using-conjur-OSS.htm
1. Go to `4-secretless` folder.
2. Update `bootstrap.env`, `secretless.yml` & `cityapp-secretless.yml`
3. Execute `1_deploy_secretless.sh`

