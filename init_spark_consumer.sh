#!/bin/bash

# Detener el script si ocurre algún error
set -e

# Cargar las variables de entorno del archivo .env
source /home/ubuntu/.env

# Actualizar los paquetes e instalar Java, Scala, Python y otras dependencias necesarias
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk scala python3-pip git curl

# Instalar Spark
echo "Instalando Spark..."
wget https://dlcdn.apache.org/spark/spark-3.3.1/spark-3.3.1-bin-hadoop3.tgz
tar xvf spark-3.3.1-bin-hadoop3.tgz
sudo mv spark-3.3.1-bin-hadoop3 /opt/spark

# Verificar la instalación de Spark
if [ ! -d "/opt/spark/bin" ]; then
  echo "Error: Spark no se ha instalado correctamente."
  exit 1
fi

# Configurar variables de entorno para Spark
echo "export SPARK_HOME=/opt/spark" >> ~/.bashrc
echo "export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin" >> ~/.bashrc
source ~/.bashrc

# Instalar Kafka
echo "Instalando Kafka..."
wget https://archive.apache.org/dist/kafka/2.13-2.8.0/kafka_2.13-2.8.0.tgz
tar xvf kafka_2.13-2.8.0.tgz
sudo mv kafka_2.13-2.8.0 /opt/kafka

# Verificar la instalación de Kafka
if [ ! -d "/opt/kafka/bin" ]; then
  echo "Error: Kafka no se ha instalado correctamente."
  exit 1
fi

# Configurar variables de entorno para Kafka
echo "export KAFKA_HOME=/opt/kafka" >> ~/.bashrc
echo "export PATH=\$PATH:\$KAFKA_HOME/bin" >> ~/.bashrc
source ~/.bashrc

# Instalar dependencias de Python
pip3 install kafka-python

# Descargar las bibliotecas necesarias para Spark Streaming con Kafka
cd /opt/spark/jars
wget https://repo1.maven.org/maven2/org/apache/spark/spark-streaming-kafka-0-10_2.12/3.3.1/spark-streaming-kafka-0-10_2.12-3.3.1.jar
wget https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.3.1/spark-sql-kafka-0-10_2.12-3.3.1.jar

# Crear el script del consumidor de Kafka con Spark
cat << 'EOF' > /home/ubuntu/spark_kafka_consumer.py
import os
from pyspark import SparkContext
from pyspark.streaming import StreamingContext
from pyspark.streaming.kafka import KafkaUtils

# Leer variables de entorno
kafka_broker = os.environ.get('EC2_PUBLIC_DNS_PRODUCER_BROKER', 'localhost:9092')
topic = os.environ.get('KAFKA_TOPIC', 'test_topic')

# Crear un contexto de Spark
sc = SparkContext(appName="PythonStreamingKafka")
ssc = StreamingContext(sc, 10)  # Intervalo de 10 segundos

# Definir los parámetros de Kafka
kafka_params = {"metadata.broker.list": kafka_broker}

# Crear un DStream desde Kafka
kafkaStream = KafkaUtils.createDirectStream(ssc, [topic], kafka_params)

# Procesar los mensajes recibidos
lines = kafkaStream.map(lambda x: x[1])
words = lines.flatMap(lambda line: line.split(" "))
wordCounts = words.map(lambda word: (word, 1)).reduceByKey(lambda x, y: x + y)

# Imprimir el resultado
wordCounts.pprint()

# Iniciar la computación
ssc.start()
ssc.awaitTermination()
EOF

# Asegurarse de que las variables de entorno están configuradas para esta sesión
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
export KAFKA_HOME=/opt/kafka
export PATH=$PATH:$KAFKA_HOME/bin

# Verificar que las variables de entorno están configuradas correctamente
echo "SPARK_HOME is set to $SPARK_HOME"
echo "KAFKA_HOME is set to $KAFKA_HOME"
echo "PATH is set to $PATH"

# Ejecutar el consumidor de Kafka con Spark
$SPARK_HOME/bin/spark-submit --jars $SPARK_HOME/jars/spark-streaming-kafka-0-10_2.12-3.3.1.jar,$SPARK_HOME/jars/spark-sql-kafka-0-10_2.12-3.3.1.jar /home/ubuntu/spark_kafka_consumer.py
