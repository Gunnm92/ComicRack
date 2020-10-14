FROM ubuntu:eoan

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN dpkg --add-architecture i386
RUN apt-get update && apt-get -y install xvfb x11vnc xdotool wget tar supervisor net-tools fluxbox gnupg2
RUN wget -O - https://dl.winehq.org/wine-builds/winehq.key | apt-key add -
RUN echo 'deb https://dl.winehq.org/wine-builds/ubuntu/ eoan main' |tee /etc/apt/sources.list.d/winehq.list
RUN apt-get update && apt-get -y install winehq-stable
RUN mkdir /opt/wine-stable/share/wine/winetricks && cd /opt/wine-stable/share/wine/winetricks && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
RUN chmod +x /opt/wine-stable/share/wine/winetricks/winetricks
RUN mkdir /tmp/comicrack && \
    cd /tmp/comicrack && \
    wget https://github.com/Gunnm92/ComicRack/raw/main/ComicRackSetup09178.exe
RUN apt-get -y full-upgrade && apt-get clean
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV WINEPREFIX /root/prefix32
ENV WINEARCH win32
ENV DISPLAY :0

WORKDIR /root/
RUN wget -O - https://github.com/novnc/noVNC/archive/v1.1.0.tar.gz | tar -xzv -C /root/ && mv /root/noVNC-1.1.0 /root/novnc && ln -s /root/novnc/vnc_lite.html /root/novnc/index.html
RUN wget -O - https://github.com/novnc/websockify/archive/v0.9.0.tar.gz | tar -xzv -C /root/ && mv /root/websockify-0.9.0 /root/novnc/utils/websockify

EXPOSE 8080

CMD ["/usr/bin/supervisord"]
