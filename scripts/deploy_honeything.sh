set -e
set -x

if [ $# -ne 2 ]
    then
        echo "Wrong number of arguments supplied."
        echo "Usage: $0 <server_url> <deploy_key>."
        exit 1
fi

server_url=$1
deploy_key=$2

apt-get update
apt-get -y install git python-pip supervisor
pip install virtualenv

# Get the honeything source
cd /opt
git clone https://github.com/prahlad574/honeything-1.git
cd honeything

virtualenv env
. env/bin/activate
pip install -r requirements.txt

python setup.py install

# Register the sensor with the MHN server.
wget $server_url/static/registration.txt -O registration.sh
chmod 755 registration.sh
# Note: this will export the HPF_* variables
. ./registration.sh $server_url $deploy_key "honeything"

cat >> wordpot.conf <<EOF
HPFEEDS_ENABLED = True
HPFEEDS_HOST = '$HPF_HOST'
HPFEEDS_PORT = $HPF_PORT
HPFEEDS_IDENT = '$HPF_IDENT'
HPFEEDS_SECRET = '$HPF_SECRET'
HPFEEDS_TOPIC = 'honeything.events'
EOF

# Config for supervisor.
cat > /etc/supervisor/conf.d/src/config/honeything.config.ini <<EOF
[program:honeything]
command=/opt/honeything/env/bin/python /opt/wordpot/setup.py 
directory=/opt/honeything
stdout_logfile=/opt/honeything/honeything.out
stderr_logfile=/opt/honeything/honeything.err
autostart=true
autorestart=true
redirect_stderr=true
stopsignal=QUIT
EOF

supervisorctl update


