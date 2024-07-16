#!/bin/bash
## Setting Go verison to be installed
go_version="1.21.5"

go_url_amd64="https://go.dev/dl/go$go_version.linux-amd64.tar.gz"
go_url_x86="https://go.dev/dl/go$go_version.linux-386.tar.gz"

function go_install() {
        apt-get update && apt-get dist-upgrade -y
        apt-get install wget unzip sudo -y
        apt autoremove -y
        if ! command -v go &> /dev/null; then
                wget -O /tmp/golang.tar.gz $go_url_amd64               
                rm -rvf /usr/local/go/
                tar -xvzf /tmp/golang.tar.gz -C /usr/local/
                rm /tmp/golang.tar.gz
                export GOPATH=/usr/local/go
                export GOCACHE=/root/.cache/go-build

                echo "Go wurde installiert (Version $go_current_version)."
        else
                # Ermitteln aktuell installierter Go Version
                go_current_version=$(go version | awk '{print $3}' | sed 's/go//')

                if [ "$go_current_version" != "$go_version" ]; then
                        echo "Versionsunterschied. Aktuell installiert ist $go_current_version. Installiert werden muss $go_version."
                        echo "Installiere Go $go_version..."
                        ## Installiere golang
                        wget -O /tmp/golang.tar.gz $go_url_amd64
                        rm -rvf /usr/local/go/
                        tar -xvzf /tmp/golang.tar.gz -C /usr/local/
                        rm /tmp/golang.tar.gz
                        export GOPATH=/usr/local/go
                        export GOCACHE=/root/.cache/go-build

                        echo "Go $go_version installiert."
                else
                        echo "Go ist aktuell (Version $go_current_version)."
                fi
        fi
}


function agent_compile() {
        ## Compiliere und installiere tactical agent von Github
        echo "Compiliere Agent"
        wget -O /tmp/rmmagent.zip "https://github.com/amidaware/rmmagent/archive/refs/heads/master.zip"
        unzip /tmp/rmmagent -d /tmp/
        rm /tmp/rmmagent.zip
        cd /tmp/rmmagent-master
        env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -o /tmp/temp_rmmagent
        cd /tmp
        rm -R /tmp/rmmagent-master
}

function update_agent() {
        systemctl stop tacticalagent

        cp /tmp/temp_rmmagent /usr/local/bin/rmmagent
        rm /tmp/temp_rmmagent

        systemctl start tacticalagent
}

function check_profile () {
        source /etc/environment
        profile_file="/root/.profile"
        path_count=$(cat $profile_file | grep -o "export PATH=/usr/local/go/bin" | wc -l)
        if [[ $path_count -ne 0 ]]; then
                sed -i "/export\ PATH\=\/usr\/local\/go\/bin/d" $profile_file
        fi

        path_count=$(cat $profile_file | grep -o "export PATH=\$PATH:/usr/local/go/bin" | wc -l)
        if [[ $path_count -ne 1 ]]; then
                sed -i "/export\ PATH\=\$PATH\:\/usr\/local\/go\/bin/d" $profile_file
                echo "export PATH=\$PATH:/usr/local/go/bin" >> $profile_file
        fi
        source $profile_file
}

check_profile
go_install
agent_compile
update_agent
echo "Tactical Agent Update ist fertig"
exit 0
