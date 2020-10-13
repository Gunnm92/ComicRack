FROM ich777/debian-buster

LABEL maintainer="admin@minenet.at"

RUN   dpkg --add-architecture i386 && \
	apt-get update && \
	apt -y install gnupg2 software-properties-common && \
	wget -qO - https://dl.winehq.org/wine-builds/winehq.key | apt-key add - && \
	apt-add-repository https://dl.winehq.org/wine-builds/debian/ && \
	wget -O- -q https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10/Release.key | apt-key add - && \
	echo "deb http://download.opensuse.org/repositories/Emulators:/Wine:/Debian/Debian_10 ./" | tee /etc/apt/sources.list.d/wine-obs.list && \
	apt-get update && \
	apt -y install --install-recommends winehq-stable && \
	apt-get -y --purge remove software-properties-common gnupg2 && \
	apt-get -y autoremove && \
	apt update && \
	
	cd "\$(mktemp -d)" && \ 
	wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
	chmod +x winetricks && \
	mv winetricks /usr/bin && \
	wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion && \
	mv winetricks.bash-completion /usr/share/bash-completion/completions/winetricks && \
	chmod +x update_winetricks && \
	mv update_winetricks /usr/bin/ && \

	rm -rf /var/lib/apt/lists/*

EXPOSE 8080

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
