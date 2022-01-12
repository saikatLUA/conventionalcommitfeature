FROM python:3.8-slim-buster

LABEL Robot Framework in Docker.

ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

# Set the working directory
WORKDIR /app

# Dependency versions
ENV ROBOT_FRAMEWORK_VERSION 4.1
ENV SELENIUM_LIBRARY_VERSION 5.1.3
ENV SSH_LIBRARY_VERSION 3.7.0
ENV REQUESTS_VERSION 0.9.1
ENV GECKO_DRIVER_VERSION v0.26.0
ENV BROWSER_LIBRARY_VERSION 6.0.0
ENV CHROMIUM_VERSION 86.0
ENV REST_LIBRARY 1.0
ENV MQTT_LIBRARY 0.7.0

# Install system dependencies
RUN DEBIAN_FRONTEND="noninteractive" \
  && apt update \
  && apt-get install -y tzdata \
  && apt-get install -y curl \
  && apt-get install -y python3 \
  && apt-get install -y python3-pip \
# Install Robot Framework and Selenium Library
  && pip3 install \
    --no-cache-dir \
    selenium \
    RESTinstance \
    schemathesis \
    robotframework-oxygen \
    robotframework==$ROBOT_FRAMEWORK_VERSION \
    robotframework-browser==$BROWSER_LIBRARY_VERSION \
    robotframework-requests==$REQUESTS_VERSION \
    robotframework-seleniumlibrary==$SELENIUM_LIBRARY_VERSION \
    robotframework-sshlibrary==$SSH_LIBRARY_VERSION \
    robotframework-restlibrary==$REST_LIBRARY \
    robotframework-mqttlibrary==$MQTT_LIBRARY
