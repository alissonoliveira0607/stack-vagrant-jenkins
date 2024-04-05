#!/bin/bash

DOCKER="https://get.docker.com/"
PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbC7fGQkGTjXERSAwLq7co5QXvahoXdG93m/Zx/+W1v+eme1ZohTCyi41MkcAJDr2KHSibwo6PE7WWjgYFAsZg/PNE6igI0D5VzC63T48tsK6ffxGFYy3rl0B/VyvHdfqe/vcw44zn6HRjF2q01DXV2NeSBZuJL+diclAcB+2jhrjha9iHWxxkJuxwFl76bAfhVdtNE6yC0It+aUtJLPT1ppcviGKpIyN1w6pGvWxk1pV+Pf6CdqU1FK05FeSPK+f34bSgIOin/DCNN6oBFgX2V5H/+Gf290bmlT9YGVSNZ0Y/HCK3Cetl3A+1j4YtbyANA3ju5mWeKeG8svzfphVRuOlKtwL+pVSrcnJuLIJqf4Nsq3PBAaPt9xzHk5vkmVfaMftQU0OXrgYhP2455SuuhpJe4LG3uyncRAXCK1AX7OoDI5jY6C4pZM00Vv+FOu5BYZLn28vr73B/rHBMzjnOCiouLbrYiCSL9VGtLcPTx4haoTWbm7fZSakyUhITI6M= alissonoliveira@ALISSON"
sudo bash -c "echo 'IP=$(hostname -I | awk "{print \$2}")' >> /etc/environment"
source /etc/environment

echo "Criando o usuário do jenkins e dando permissão de sudo"
sudo useradd -m -d /home/jenkins -s /bin/bash jenkins && \

sudo echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/jenkins

echo "Garantindo a instalação do Docker"
wget -O install_docker.sh https://get.docker.com/ && chmod a+x install_docker.sh; sudo bash -c "./install_docker.sh"

echo "Incluindo o usuário do Jenkins no grupo do Docker"
sudo usermod -aG docker jenkins

sudo bash -c "echo '$PUBLIC_KEY' >> /home/vagrant/.ssh/authorized_keys"

sudo cp -r /home/vagrant/.ssh/ /home/jenkins/

sudo chown -R jenkins:jenkins /home/jenkins/.ssh

echo "Garantindo a atualização dos pacotes e instalação de dependências necessárias"
sudo apt-get update -y && \
sudo apt-get install swapspace python python3-pip python-dev libmysqlclient-dev python3-venv  build-essential libssl-dev libffi-dev unzip -y


sudo apt-get update -y && \
    apt-get install -y openjdk-8-jdk  mysql-server-5.7 curl wget jq vim default-jdk -y && \
    mysql -e "create user 'devops'@'%' identified by 'devops';"  && \
    mysql -e "create user 'devops_dev'@'%' identified by 'devops';"  && \
    mysql -e "create database todo;" && \
    mysql -e "create database todo_dev;" && \
    mysql -e "create database test_todo_dev;" && \
    mysql -e "grant all privileges on *.* to devops@'%' identified by 'devops';" && \
    mysql -e "grant all privileges on *.* to devops_dev@'%' identified by 'devops';" 

sudo cat <<EOF | sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf
#
# The MySQL database server configuration file.
#
# You can copy this to one of:
# - "/etc/mysql/my.cnf" to set global options,
# - "~/.my.cnf" to set user-specific options.
#
# One can use all long options that the program supports.
# Run program with --help to get a list of available options and with
# --print-defaults to see which it would actually understand and use.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

# This will be passed to all mysql clients
# It has been reported that passwords should be enclosed with ticks/quotes
# escpecially if they contain "#" chars...
# Remember to edit /etc/mysql/debian.cnf when changing the socket location.

# Here is entries for some specific programs
# The following values assume you have at least 32M ram

[mysqld_safe]
socket		= /var/run/mysqld/mysqld.sock
nice		= 0

[mysqld]
#
# * Basic Settings
#
user		= mysql
pid-file	= /var/run/mysqld/mysqld.pid
socket		= /var/run/mysqld/mysqld.sock
port		= 3306
basedir		= /usr
datadir		= /var/lib/mysql
tmpdir		= /tmp
lc-messages-dir	= /usr/share/mysql
skip-external-locking
#
# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
#bind-address		= 0.0.0.0
#
# * Fine Tuning
#
key_buffer_size		= 16M
max_allowed_packet	= 16M
thread_stack		= 192K
thread_cache_size       = 8
# This replaces the startup script and checks MyISAM tables if needed
# the first time they are touched
myisam-recover-options  = BACKUP
#max_connections        = 100
#table_open_cache       = 64
#thread_concurrency     = 10
#
# * Query Cache Configuration
#
query_cache_limit	= 1M
query_cache_size        = 16M
#
# * Logging and Replication
#
# Both location gets rotated by the cronjob.
# Be aware that this log type is a performance killer.
# As of 5.1 you can enable the log at runtime!
#general_log_file        = /var/log/mysql/mysql.log
#general_log             = 1
#
# Error log - should be very few entries.
#
log_error = /var/log/mysql/error.log
#
# Here you can see queries with especially long duration
#slow_query_log		= 1
#slow_query_log_file	= /var/log/mysql/mysql-slow.log
#long_query_time = 2
#log-queries-not-using-indexes
#
# The following can be used as easy to replay backup logs or for replication.
# note: if you are setting up a replication slave, see README.Debian about
#       other settings you may need to change.
#server-id		= 1
#log_bin			= /var/log/mysql/mysql-bin.log
expire_logs_days	= 10
max_binlog_size   = 100M
#binlog_do_db		= include_database_name
#binlog_ignore_db	= include_database_name
#
# * InnoDB
#
# InnoDB is enabled by default with a 10MB datafile in /var/lib/mysql/.
# Read the manual for more InnoDB related options. There are many!
#
# * Security Features
#
# Read the manual, too, if you want chroot!
# chroot = /var/lib/mysql/
#
# For generating SSL certificates I recommend the OpenSSL GUI "tinyca".
#
# ssl-ca=/etc/mysql/cacert.pem
# ssl-cert=/etc/mysql/server-cert.pem
# ssl-key=/etc/mysql/server-key.pem
EOF

sudo systemctl restart mysql

# echo "Atualizando os pacotes necessários"
# sudo apt update -y

#sudo apt install curl wget jq vim default-jdk -y


echo "Garantindo GPG e repositório do Jenkins"
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

sudo echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y

echo "Instalando o Jenkins"
sudo apt install jenkins -y



echo "Secret JENKINS: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"