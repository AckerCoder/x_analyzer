from kafka import KafkaProducer
import json
from dotenv import load_dotenv

# Cargar variables de entorno desde config.env
load_dotenv('/home/ec2-user/config.env')

# Configurar el productor de Kafka
producer = KafkaProducer(
    bootstrap_servers=['kafka:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Nombre del tema de Kafka
topic_name = 'my_topic'

# Enviar mensajes al tema de Kafka
for i in range(100):
    message = {'number': i}
    producer.send(topic_name, value=message)
    print(f'Sent: {message}')

# Cerrar el productor
producer.close()
