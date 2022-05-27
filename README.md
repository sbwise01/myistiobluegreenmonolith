# myistiobluegreenmonolith
A demo of using istio to perform blue green deployments on a monolithic service backend

Deployment order
1.  Terraform apply tf sub-directory
2.  kubectl apply all resources in k8s sub-directory
3.  Terraform apply tf/post_istio sub-directory
