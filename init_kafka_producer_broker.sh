#!/bin/bash

# Cargar el archivo de configuración
source /home/ubuntu/config.env

# Actualiza los paquetes e instala Docker y pip
sudo apt-get update
sudo apt-get install -y docker.io python3-pip

# Inicia Docker
sudo systemctl start docker
sudo systemctl enable docker

docker network create kafka-network

# Agrega el usuario actual al grupo de Docker
sudo usermod -aG docker ubuntu

# Descargar y ejecutar la imagen de Kafka de Bitnami
docker pull bitnami/kafka:latest

# Ejecutar Kafka Broker conectándose al ZooKeeper externo
sudo docker run -d --name kafka --network kafka-network -p 9092:9092 \
    -e KAFKA_CFG_ZOOKEEPER_CONNECT=$ZOOKEEPER_IP:2181 \
    -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://$(hostname -I | awk '{print $1}'):9092 \
    -e KAFKA_CFG_LISTENERS=PLAINTEXT://0.0.0.0:9092 \
    bitnami/kafka:latest

# Construir la imagen Docker usando Dockerfile.kafka-producer
docker build -t kafka-producer -f Dockerfile.kafka-producer .

sleep 10
docker logs kafka

# Ejecutar el contenedor Docker usando el archivo de configuración config.env
docker run --network kafka-network --env-file config.env kafka-producer

