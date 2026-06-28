#!/bin/bash

ENVIRONMENT=$1
VERSION=$2
REGISTRY=$3

if [ "$#" -ne 3 ]; then
    echo "Usage: ./deploy.sh <environment> <version> <image_registry>"
    exit 1
fi

case "$ENVIRONMENT" in
    dev|staging|prod)
        ;;
    *)
        echo "Invalid environment."
        exit 1
        ;;
esac

LOG_FILE="deployment.log"

echo "Deployment Started: $(date)" >> "$LOG_FILE"

echo "Deploying version $VERSION" >> "$LOG_FILE"


command -v kubectl >/dev/null 2>&1 || {
    echo "kubectl not found."
    exit 1
}

command -v helm >/dev/null 2>&1 || {
    echo "helm not found."
    exit 1
}


helm upgrade --install flask-api ./helm/flask-api \
    --set image.repository=$REGISTRY/flask-api \
    --set image.tag=$VERSION \
    --wait


helm upgrade --install flask-api ./helm/flask-api \
    --set image.repository=docker.io/yash/flask-api \
    --set image.tag=v1.0.5 \
    --wait

kubectl port-forward service/flask-api-service 5000:5000 &
sleep 5

curl --fail http://localhost:5000/health

if curl --fail http://localhost:5000/health
then
    echo "Smoke Test Passed"
    echo "Deployment Successful" >> deployment.log
else
    echo "Smoke Test Failed"
    helm rollback flask-api
    echo "Rollback Executed" >> deployment.log
    exit 1
fi