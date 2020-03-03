kubectl create secret generic mysql01-secret --from-literal=password=<db password>

kubectl apply -n cityapp  -f 2-k8s-secret/cityapp-k8s-secret.yaml
