#!/bin/sh

# PV could be empty, make sure the directories exist
mkdir -p /var/lib/rmt/public/repo
mkdir -p /var/lib/rmt/public/suma
mkdir -p /var/lib/rmt/regsharing
mkdir -p /var/lib/rmt/tmp
# Set permissions
chown -R _rmt:nginx /var/lib/rmt

if [ -z "${RMT_REMOTE_HOST}" ]; then
	echo "RMT_REMOTE_HOST not set!"
	exit 1
fi

if [ -z "${RSYNC_USER}" ]; then
	echo "RSYNC_USER not set!"
	exit 1
fi

# Create keypair if not exist yet
if ! [ -f ~/.ssh/id_rsa ]; then
	ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa
fi

# Create/update known_hosts
if ! [ -f ~/.ssh/known_hosts ]; then
	ssh-keygen -R ${RMT_REMOTE_HOST}
fi
ssh-keyscan -H ${RMT_REMOTE_HOST} >> ~/.ssh/known_hosts

# Run cron in foreground
cron -f&

# Copy public key to the remote RMT for passwordless login by cert
sshpass -p "${USER_PASS}" ssh-copy-id -i ~/.ssh/id_rsa.pub -p 22 ${RSYNC_USER}@${RMT_REMOTE_HOST}

if [ -z "${MYSQL_HOST}" ]; then
	echo "MYSQL_HOST not set!"
	exit 1
fi
if [ -z "${MYSQL_PASSWORD}" ]; then
        echo "MYSQL_PASSWORD not set!"
        exit 1
fi

if [ -z "${MYSQL_PWD}" ]; then
        echo "MYSQL_PWD not set!"
        exit 1
fi

MYSQL_DATABASE="${MYSQL_DATABASE:-rmt}"
MYSQL_USER="${MYSQL_USER:-rmt}"

# Create adjusted /etc/rmt.conf
echo -e "database:\n  host: ${MYSQL_HOST}\n  database: ${MYSQL_DATABASE}\n  username: ${MYSQL_USER}\n  password: ${MYSQL_PASSWORD}" > /etc/rmt.conf
echo -e "  adapter: mysql2\n  encoding: utf8\n  timeout: 5000\n  pool: 5\n" >> /etc/rmt.conf
echo -e "scc:\n  username: ${SCC_USERNAME}\n  password:  ${SCC_PASSWORD}\n  sync_systems: true\n" >> /etc/rmt.conf
echo -e "log_level:\n  rails: debug" >> /etc/rmt.conf

if [ $# -eq 0 ]; then
	set -- /usr/share/rmt/bin/rails server -e production
fi

if [ "$1" == "/usr/share/rmt/bin/rails" -a "$2" == "server" ]; then
        echo "Create/migrate RMT database"
	pushd /usr/share/rmt > /dev/null
	/usr/share/rmt/bin/rails db:create db:migrate RAILS_ENV=production
	popd > /dev/null
        echo "Executing: catatonit -- $@"
        exec catatonit -- "$@"
else
	echo "Executing: $@"
	exec "$@"
fi

if ! [ -f /var/lib/rmt/public/repo/organizations_products.json ]; then
	echo "Sync rmt settings"
	rsync -e "ssh -p 22" ${RSYNC_USER}@${RMT_REMOTE_HOST}:~/rmt/* ~/rmt-container/public/repo/
	chown -R _rmt:nginx /var/lib/rmt/public/
	echo "Import data to the local RMT"
	rmt-cli import data /var/lib/rmt/public/repo/
fi

if ! [ -d /var/lib/rmt/public/repo/SUSE/Products ]; then
	echo "Sync repos (first time maybe too long)"
	rsync -aqe "ssh -p 22" --delete --exclude '*.json' ${RSYNC_USER}@${RMT_REMOTE_HOST}:/var/lib/rmt/public/* /var/lib/rmt/public
	chown -R _rmt:nginx /var/lib/rmt/public/
	echo "Import repos to the local RMT"
	rmt-cli import repos /var/lib/rmt/public/repo/
fi
