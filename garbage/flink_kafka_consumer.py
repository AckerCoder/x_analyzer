from pyflink.datastream import StreamExecutionEnvironment
from pyflink.datastream.connectors import FlinkKafkaConsumer
from pyflink.common.serialization import SimpleStringSchema
import os

def main():
    env = StreamExecutionEnvironment.get_execution_environment()

    properties = {
        'bootstrap.servers': os.getenv('EC2_PUBLIC_DNS_PRODUCER_BROKER') + ':9092',
        'group.id': 'flink_consumer_group'
    }

    kafka_consumer = FlinkKafkaConsumer(
        topics='my_topic',
        deserialization_schema=SimpleStringSchema(),
        properties=properties
    )

    data_stream = env.add_source(kafka_consumer)

    data_stream.print()

    env.execute("Flink Kafka Consumer")

if __name__ == '__main__':
    main()
