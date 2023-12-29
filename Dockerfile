FROM ich777/debian-bullseye
LABEL maintainer="admin@minenet.at"

RUN dpkg --add-architecture i386 && \
	apt update && \
	apt -y install --install-recommends gnupg2 software-properties-common cabextract && \
	mkdir -pm755 /etc/apt/keyrings && \
	wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
	wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bullseye/winehq-bullseye.sources && \
	apt update && \
	apt -y install --install-recommends winehq-stable && \
	
	mkdir /tmp/winetricks && \
	cd /tmp/winetricks && \ 
	wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
	cp winetricks /usr/bin/winetricks && \
	chmod +x /usr/bin/winetricks && \
	rm -rf /tmp/winetricks && \
	mkdir /tmp/comicrack && \
	cd /tmp/comicrack && \
	wget https://github.com/Gunnm92/ComicRack/raw/main/ComicRackSetup09178.exe && \
	
	apt-get -y --purge remove software-properties-common gnupg2 && \
	apt-get -y autoremove && \

	rm -rf /var/lib/apt/lists/*

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
