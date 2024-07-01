#!/bin/bash

# Cargar las variables de entorno del archivo .env
source .env

# Subir los archivos necesarios al servidor EC2
scp -i $PEM_PATH ./docker-compose-flink.yml ./scripts/flink_kafka_consumer.py ./Dockerfile.flink-consumer ./start-flink-cluster.sh ./init_flink_consumer.sh .env ubuntu@$EC2_PUBLIC_DNS_FLINK_CONSUMER:/home/ubuntu/

# Conectar al servidor EC2 y ejecutar el script de inicialización
ssh -i $PEM_PATH ubuntu@$EC2_PUBLIC_DNS_FLINK_CONSUMER 'chmod +x /home/ubuntu/init_flink_consumer.sh && /home/ubuntu/init_flink_consumer.sh'
