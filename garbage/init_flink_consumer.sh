#!/bin/bash

# Cargar las variables de entorno del archivo .env
source /home/ubuntu/.env

# Actualiza los paquetes e instala Docker y Python
sudo apt-get update
sudo apt-get install -y docker.io python3-pip git

# Inicia Docker
sudo systemctl start docker
sudo systemctl enable docker

# Agrega el usuario actual al grupo de Docker
sudo usermod -aG docker ubuntu

# Instala Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Crear directorios necesarios
mkdir -p /home/ubuntu/flink-consumer

# Mover los archivos necesarios al directorio correcto
mv /home/ubuntu/docker-compose-flink.yml /home/ubuntu/
mv /home/ubuntu/Dockerfile.flink-consumer /home/ubuntu/flink-consumer/
mv /home/ubuntu/start-flink-cluster.sh /home/ubuntu/flink-consumer/
mv /home/ubuntu/flink_kafka_consumer.py /home/ubuntu/flink-consumer/
mv /home/ubuntu/.env /home/ubuntu/flink-consumer/

# Construir la imagen personalizada de Python para el consumidor de Kafka
cd /home/ubuntu/flink-consumer
docker build -t flink-consumer -f Dockerfile.flink-consumer .

# Iniciar el clúster de Flink y el consumidor
cd /home/ubuntu
docker-compose -f docker-compose-flink.yml up -d
