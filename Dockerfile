# Define global args
ARG FUNCTION_DIR="/home/app/"
ARG RUNTIME_VERSION="3.9"
ARG DISTRO_VERSION="3.12"


# Stage 1 - bundle base image + runtime
# Grab a fresh copy of the image and install GCC
FROM python:${RUNTIME_VERSION}-alpine${DISTRO_VERSION} AS python-alpine
# Install GCC (Alpine uses musl but we compile and link dependencies with GCC)
RUN apk add --no-cache \
    libstdc++


# Stage 2 - build function and dependencies
FROM python-alpine AS build-image
# Install aws-lambda-cpp build dependencies
RUN apk add --no-cache \
    build-base \
    libtool \
    autoconf \
    automake \
    libexecinfo-dev \
    make \
    cmake \
    libcurl
# Include global args in this stage of the build
ARG FUNCTION_DIR
ARG RUNTIME_VERSION
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}
# Install Lambda Runtime Interface Client for Python
RUN python${RUNTIME_VERSION} -m pip install awslambdaric --target ${FUNCTION_DIR}


# Stage 3 - Add app related dependencies
FROM python-alpine as build-image2
ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}
# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
# Copy over and install requirements
RUN apk update \
    && apk add gcc python3-dev musl-dev \
    && apk add jpeg-dev zlib-dev libjpeg-turbo-dev
COPY requirements.txt .
RUN python${RUNTIME_VERSION} -m pip install -r requirements.txt --target ${FUNCTION_DIR}


# Stage 4 - final runtime image
# Grab a fresh copy of the Python image
FROM python-alpine
ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}
# Copy in the built dependencies
COPY --from=build-image2 ${FUNCTION_DIR} ${FUNCTION_DIR}
RUN apk add jpeg-dev zlib-dev libjpeg-turbo-dev \
    && apk add chromium chromium-chromedriver
# (Optional) Add Lambda Runtime Interface Emulator and use a script in the ENTRYPOINT for simpler local runs
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie
RUN chmod 755 /usr/bin/aws-lambda-rie
# Copy handler function
COPY app/* ${FUNCTION_DIR}
COPY entry.sh /
ENTRYPOINT [ "/entry.sh" ]
CMD [ "app.handler" ]