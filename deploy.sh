#!/bin/bash

echo "Building Docker image..."

docker build -t flask-api:v0.0.0 .

echo "Running Container..."

docker run -p 5000:5000 flask-api:v0.0.0