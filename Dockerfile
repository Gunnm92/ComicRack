FROM ich777/debian-buster

LABEL maintainer="admin@minenet.at"

RUN dpkg --add-architecture i386 && \
	apt-get update && \
	apt -y install --install-recommends gnupg2 software-properties-common cabextract && \
	wget -qO - https://dl.winehq.org/wine-builds/winehq.key | apt-key add - && \
	apt-add-repository https://dl.winehq.org/wine-builds/debian/ && \
	wget -O- -q https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key | apt-key add - && \
	echo "deb http://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10 ./" | tee /etc/apt/sources.list.d/wine-obs.list && \
	apt-get update && \
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
