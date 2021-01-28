# Manage Prometheus and Grafana in Kubernetes cluster with Helm (TLS Configuration)
___________________________________________________________________________________

**NOTE:** This project has been tested on a GKE cluster of GCP but it can work for all clusters (No specific resources for google in the project)

## Provider
* kubernetes 
* helm

## Connect to the Cluster
* Get the kubeConfig file of the cluster
```bash
gcloud container clusters get-credentials cluster-name  --region region-name --zone zone-name --project project-name
```
* Put the kube/config path in your provider.tf file in Terraform configuration

## Prometheus, Grafana and Ingres controller
I used Helm provider in Terraform to install and configure prometheus, grafana (Prometheus Operator contains prometheus, alertmanager and grafana)and ingress controller

* [Chart prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
* [Chart ingress controller](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx)
* [Chart Cert manager](https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager)

## Ingress Controller (Loadbalancer)
In order to access the grafana service (Cluster IP), I created an ingress resource.
I managed this with Terraform kubernetes resource.

[Manage Ingress resource and Ingress Controller](https://cloud.google.com/community/tutorials/nginx-ingress-gke)

## Manage DNS
In order to access the service with URL,I managed dns record.
I created a domain name in easyence-tools that points to the address of ingress controller(LoadBalancer).

## TLS and HTTPS Access
I managed the certificate in order to access the grafana service in HTTPS.
The certificate is managed by LETSENCRYPT and CERTMANAGER.

[How to Manage Cert manager ?](https://cert-manager.io/docs/installation/kubernetes/)

[How to use letsencrypt ?](https://github.com/jetstack/cert-manager)

### Create ClusterIssuer and Certificate resource

* Check **certificate.yaml** file to have example

## Grafana dashboard

In order to protect access to grafana, password is manage by kubernetes secret resource.

```bash
Username: admin
Password: kubectl get secret --namespace monitoring prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## Usage

NB: Manage your DNS zone and dns records like this:

    * for zone **example.com**, we have two dns records:

      nginx.example.com ---> A ---> @ip_ingress_controller

      *.demo.example.com ---> CNAME ----> nginx.example.com

```bash
cd terraform-PrometheusOperator-helm-Tls
terraform init
terraform plan -out=run.plan
terraform apply run.plan
kubectl apply -f manifests/certificate.yaml
```
## Check a certifficate
Check a tls.crt and tls.key in SecretName
```
kubectl describe  secret  tls-cert -n monitoring
```
and you will have this type of result :

```yaml
Name:         tls-cert
Namespace:    monitoring
Labels:       <none>
Annotations:  cert-manager.io/alt-names: grafana.tools.easyence.io
              cert-manager.io/certificate-name: tls-cert
              cert-manager.io/common-name: grafana.tools.easyence.io
              cert-manager.io/ip-sans: 
              cert-manager.io/issuer-group: cert-manager.io
              cert-manager.io/issuer-kind: ClusterIssuer
              cert-manager.io/issuer-name: letsencrypt-prod
              cert-manager.io/uri-sans: 

Type:  kubernetes.io/tls

Data
====
tls.crt:  3456 bytes
tls.key:  1679 bytes
```
## References
* [Example of monitoring article with grafana/prometheus](https://medium.com/swlh/free-ssl-certs-with-lets-encrypt-for-grafana-prometheus-operator-helm-charts-b3b629e84ba1)

* [Test with cluster-issuer in Stack Overflow](https://stackoverflow.com/questions/58423312/how-do-i-test-a-clusterissuer-solver/58436097?noredirect=1#comment103215785_58436097)

* [Understand Certificate with Letsencrypt-prod, Certificate, ClusterIssuer and Issuer](https://docs.cert-manager.io/en/release-0.11/reference/certificates.html)
