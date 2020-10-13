FROM ich777/debian-buster

LABEL maintainer="admin@minenet.at"

RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
      apt-key add winehq.key && \
      apt-add-repository deb 'https://dl.winehq.org/wine-builds/debian/ buster main' && \
      apt update && \
      apt install --install-recommends winehq-stable

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
