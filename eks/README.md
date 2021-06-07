# Initial setup of a EKS cluster

eksctl create cluster --config-file cluster-1.yaml


# Install ingress-controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/deploy.yaml


# Install ArgoCD
kubectl create namespace argocd 2> /dev/null || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.0.2/manifests/install.yaml
kubectl apply -n argocd -f argocd-ingress.yaml
