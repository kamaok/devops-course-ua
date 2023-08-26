#!/usr/bin/env bash

set -e

# Variables available to change
MYSQL_ROOT_PASSWORD="MysqlPass123$"
MYSQL_USER="world_user"
MYSQL_PASSWORD="MysqlUserPass123$"
EMAIL_HOST_USER="user@gmail.com"
EMAIL_HOST_PASSWORD="EmailPass"

source "$(dirname "$0")"/.env > /dev/null 2>&1 || true

# Don't touch it
MYSQL_DEP_NOT_SATISFIED="false"
PYTHON_DEP_NOT_SATISFIED="false"



# Check whether distibutive is supported by the script
OS_DISTRIBUTIVE=$(. /etc/os-release && echo "$ID")
if [[ ! -e /etc/os-release  || $OS_DISTRIBUTIVE != "ubuntu" && $OS_DISTRIBUTIVE != "centos" ]]
  then
    echo "Current distributive is not supported by script. Only ubuntu and centos are supported"
fi

usage() {
echo -e "\nUSAGE: ${0}\n"

cat << EOF
1. Script for autoinstallation application from the repo
https://github.com/Manisha-Bayya/simple-django-project

2. Script was tested on Ubuntu-20 and Centos-7

3. Configure these parameters/variables in this script or create a separate file with the name .env and host all/some of these variables in the .env file
- MYSQL_ROOT_PASSWORD
- MYSQL_USER
- MYSQL_PASSWORD
- EMAIL_HOST_USER
- EMAIL_HOST_PASSWORD

Whether you use the script on Centos you should set up MySQL passwords according to the password policy:
The default password policy implemented by validate_password requires that passwords contain at least one uppercase letter, one lowercase letter, one digit, and one special character and that the total password length is at least 8 characters.
During MySQL installation, you should enter the same root MySQL password as you defined in the variable MYSQL_ROOT_PASSWORD by installation request.

4. Script check whether required MySQL and Python software is installed and whether the installed software is compatible with MySQL 8.0.X and Python 3.7.X
Whether any dependency(MySQL/Python) isn't installed the script proposes to a user to install it automatically.
Whether the user doesn't agree to install any missed dependency the script stops execution and exit
EOF
}

# Print usage information for help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Check mysql exist and its version
check_mysql_exist_and_version () {
set +e
#command mysql -V > /dev/null 2>&1
#if [[ $? -ne "0" || ! $(mysql -V 2>&1 | grep Ver | awk '{print $3}') =~ 8.0.* ]]; then
if ! command mysql -V > /dev/null 2>&1 || [[  ! $(mysql -V 2>&1 | grep Ver | awk '{print $3}') =~ 8.0.* ]]; then
  MYSQL_DEP_NOT_SATISFIED="true"
fi
}

# Check python exist and its version
check_python_exist_and_version () {
set +e
if ! python3 --version > /dev/null 2>&1 && ! python --version > /dev/null 2>&1 && ! python3.7 --version > /dev/null 2>&1; then
  PYTHON_DEP_NOT_SATISFIED="true"
fi
if [[ ! $(python --version 2>&1 | awk '{print $2}') =~ 3.7.* && ! $(python3 --version 2>&1| awk '{print $2}') =~ 3.7.* && ! $(python3.7 --version 2>&1 | awk '{print $2}') =~ 3.7.* ]]; then
  PYTHON_DEP_NOT_SATISFIED="true"
fi
}

# Install python 3.7 and pip on Ubuntu
python_and_pip_installation_ubuntu () {
set -e
apt-get install -y software-properties-common git
echo "yes" | add-apt-repository ppa:deadsnakes/ppa
apt-get update
apt-get install -y python 3.7 python3.7-venv
python3.7 --version

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
pip --version
}

# Install python 3.7 and pip on Centos
python_and_pip_installation_centos () {
set -e
yum -y install wget make gcc openssl-devel bzip2-devel libffi-devel git
cd /tmp/
[[ -e Python-3.7.2.tgz ]] && rm -f Python-3.7.2.tgz
wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
tar xzf Python-3.7.2.tgz
cd Python-3.7.2
./configure --enable-optimizations
make altinstall
ln -sfn /usr/local/bin/python3.7 /usr/bin/python3.7
ln -sfn /usr/local/bin/pip3.7 /usr/bin/pip3.7
python3.7 --version
cd "$HOME"
rm -rf Python-3.7.2*
}

# Install and base configuration MySQL 8.0.X on Ubuntu
mysql_installation_ubuntu () {
set -e
echo "Installtion MySQL 8.0.X"
cat  << 'EOF' > mysql_public.key
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: SKS 1.1.6
Comment: Hostname: pgp.mit.edu

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
sTSKHe+QnnnoFmu4gnmDU31i
=Xqbo
-----END PGP PUBLIC KEY BLOCK-----
EOF
apt-key add mysql_public.key
# Alternative add key
#apt-key adv --keyserver pgp.mit.edu --recv-keys 3A79BD29
cat << EOF > /etc/apt/sources.list.d/mysql.list
deb http://repo.mysql.com/apt/$(. /etc/os-release && echo "$ID") $(. /etc/os-release && echo "$VERSION_CODENAME") mysql-8.0
EOF
apt-get update
apt-get install -y mysql-server libmysqlclient-dev
mysql_secure_installation << EOF
n
n
y
y
y
y
EOF
}


# Install and base configuration MySQL 8.0.X on Centos
mysql_installation_centos () {
set -e
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-10.noarch.rpm
yum install -y mysql-community-server mysql-community-devel
systemctl start mysqld
TEMP_MYSQL_ROOT_PASSWORD=$(awk '/temporary/ {print $NF}' /var/log/mysqld.log)
echo "$TEMP_MYSQL_ROOT_PASSWORD"

cat << EOF > mysql_centos.sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOF

mysql -u root -p"${TEMP_MYSQL_ROOT_PASSWORD}" --connect-expired-password < mysql_centos.sql && rm -f mysql_centos.sql
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" --connect-expired-password -e "show databases"

mysql_secure_installation << EOF
n
y
y
y
y
EOF
}


# Interactive MySQL install prompt
interactive_mysql_install () {
echo "Should we install MySQL required version whether it is not installed: [yes/no]"
read -r MYSQL_INSTALL
if [[ ${MYSQL_INSTALL} == "yes" ]]; then echo "MySQL will be installed"
    elif [[ ${MYSQL_INSTALL} == "no" ]]; then echo "ERROR: MySQL is not installed or installed MySQL version is not compatibiity with required 8.0.15 and you didn't chose to install it" && exit 1
    else echo -e "\nIncorrect answer. Correct answers: yes or no only" && interactive_mysql_install
fi
}

# Interactive Python install prompt
interactive_python_install () {
echo "Should we install Python required version whether it is not installed: [yes/no]"
read -r PYTHON_INSTALL
if [[ ${PYTHON_INSTALL} == "yes" ]]; then echo "Python will be installed";
    elif [[ ${PYTHON_INSTALL} == "no" ]]; then echo "ERROR: Python is not installed or installed Python version is not compatibiity with required 3.7.2 and you didn't chose to install it" && exit 1
    else echo -e "\nIncorrect answer. Correct answers: yes or no only!!!" && interactive_python_install
fi
}


check_mysql_exist_and_version

if [[ ${MYSQL_DEP_NOT_SATISFIED} == "true" ]]; then interactive_mysql_install; fi


check_python_exist_and_version

if [[ ${PYTHON_DEP_NOT_SATISFIED} == "true" ]]; then interactive_python_install; fi


if [[ ${MYSQL_INSTALL} == "yes" ]]; then mysql_installation_"$OS_DISTRIBUTIVE"; fi
if [[ ${PYTHON_INSTALL} == "yes" ]]; then python_and_pip_installation_"$OS_DISTRIBUTIVE"; fi


# Setup virtual environment
if [[ $OS_DISTRIBUTIVE = "ubuntu" ]]; then PIP_NAME=pip; else PIP_NAME=pip3.7; fi

$PIP_NAME install virtualenv

[ -d envs ] && rm -rf envs
virtualenv --python /usr/bin/python3.7 ./envs/
source envs/bin/activate

#  Clone git repository and install requirements
[ -d app ] && rm -rf app
git clone "https://github.com/Manisha-Bayya/simple-django-project.git" app
cd app
pip install -r requirements.txt


# Create app user with required privileges to database world
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}'"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON world.* to '${MYSQL_USER}'@'localhost'"

# Load sample data into MySQL database
mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} < world.sql


# Configure project settings
sed -i -e "s/'USER':.*,/'USER': '${MYSQL_USER}',/" \
-e "s/'PASSWORD':.*/'PASSWORD': '${MYSQL_PASSWORD}',/" \
-e "s/EMAIL_HOST_USER.*/EMAIL_HOST_USER = '${EMAIL_HOST_USER}'/" \
-e "s/EMAIL_HOST_PASSWORD.*/EMAIL_HOST_PASSWORD = '${EMAIL_HOST_PASSWORD}'/" \
panorbit/settings.py

# Fix mix tabs and spaces in indentation in source code
sed -i 's/return ("country-code: %s language: %s")/        return ("country-code: %s language: %s") %(self.countrycode.name, self.language)/'  world/models.py

## Make migrations
python manage.py makemigrations
python manage.py migrate

# For search feature we need to index certain tables to the haystack. For that run below command.
echo "yes" | python manage.py rebuild_index

# Run the server
python manage.py runserver 0:8001 &

echo "Installtion application finished successfully and available in browser http://localhost:8001"
