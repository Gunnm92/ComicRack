FROM ich777/debian-buster

LABEL maintainer="admin@minenet.at"

RUN sed -i '/deb http:\/\/deb.debian.org\/debian buster main/c\deb https:\/\/dl.winehq.org\/wine-builds\/debian buster main' /etc/apt/sources.list && \
      apt update && \
      apt install --install-recommends winehq-stable

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
