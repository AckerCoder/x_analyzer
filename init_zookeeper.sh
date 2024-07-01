#!/bin/bash

# Cargar el archivo de configuración (si es necesario)
# source /home/ubuntu/config.env

# Actualiza los paquetes e instala Docker
sudo apt-get update
sudo apt-get install -y docker.io

# Inicia Docker
sudo systemctl start docker
sudo systemctl enable docker

# Agrega el usuario actual al grupo de Docker
sudo usermod -aG docker ubuntu

# Descargar y ejecutar la imagen de ZooKeeper
docker pull zookeeper:3.6.3
sudo docker run -d --name zookeeper -p 2181:2181 zookeeper:3.6.3
