#!/bin/bash

docker build -t myconsul consul/
docker run -d --name consul -p 8500:8500 -p 8600:8600/udp myconsul