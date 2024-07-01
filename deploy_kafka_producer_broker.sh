#!/bin/bash

# Cargar variables desde el archivo .env
source .env

# Subir el script a la instancia del Kafka Broker
scp -i $PEM_PATH init_kafka_producer_broker.sh ubuntu@$EC2_PUBLIC_DNS_PRODUCER_BROKER:/home/ubuntu/
scp -i $PEM_PATH Dockerfile.kafka-producer ubuntu@$EC2_PUBLIC_DNS_PRODUCER_BROKER:/home/ubuntu/
scp -i $PEM_PATH $KAFKA_PRODUCER_SCRIPT ubuntu@$EC2_PUBLIC_DNS_PRODUCER_BROKER:/home/ubuntu/
scp -i $PEM_PATH config.env ubuntu@$EC2_PUBLIC_DNS_PRODUCER_BROKER:/home/ubuntu/

# Ejecutar el script en la instancia del Kafka Broker
ssh -i $PEM_PATH ubuntu@$EC2_PUBLIC_DNS_PRODUCER_BROKER << EOF
    chmod +x /home/ubuntu/init_kafka_producer_broker.sh
    /home/ubuntu/init_kafka_producer_broker.sh
EOF
