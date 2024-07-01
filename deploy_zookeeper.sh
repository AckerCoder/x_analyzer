#!/bin/bash

# Cargar variables desde el archivo .env
source .env

# Subir el script a la instancia de ZooKeeper
scp -i $PEM_PATH init_zookeeper.sh ubuntu@$EC2_PUBLIC_DNS_ZOOKEEPER:/home/ubuntu/

# Ejecutar el script en la instancia de ZooKeeper
ssh -i $PEM_PATH ubuntu@$EC2_PUBLIC_DNS_ZOOKEEPER << EOF
    sudo chmod +x /home/ubuntu/init_zookeeper.sh
    sudo /home/ubuntu/init_zookeeper.sh
EOF
