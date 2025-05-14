ma cow
source ~/.scripts/cloud_login.sh
gcloud container clusters get-credentials cow-gke --region us-central1
kubectl config use-context gke_ml-dev-a7b7_us-central1_cow-gke
kubectl config set-context gke_ml-dev-a7b7_us-central1_cow-gke --namespace=argo

cow
