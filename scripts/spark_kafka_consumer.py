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
