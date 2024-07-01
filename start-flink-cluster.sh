#!/bin/bash

# Start Flink Job Manager and Task Manager
start-cluster.sh

# Run the Flink Kafka consumer script
python3 flink_kafka_consumer.py
