FROM ubuntu:16.04

RUN apt-get update && apt-get -y install openjdk-8-jdk-headless gcc g++ make

WORKDIR /rti_workspace

COPY /lib/x64Linux3gcc5.4.0 ./lib/x64Linux3gcc5.4.0/
COPY /lib/java ./lib/java/
COPY /lib/start.sh ./

ENV NDDSHOME /rti_workspace
ENV PATH $PATH:$NDDSHOME/bin

ENTRYPOINT ["./start.sh"]
