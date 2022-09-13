FROM registry.opensuse.org/opensuse/rmt-server:2.9

# expect a build-time variable
ARG USERNAME
ARG HOST
# use the value to set the ENV var default
ENV RSYNC_USER=$USERNAME
ENV RMT_REMOTE_HOST=$HOST

# Add package for rsync
RUN zypper --non-interactive install --no-recommends rsync openssh-clients cronie

# Prventing usage SCC
#RUN echo "'127.0.0.2       suse.com scc.suse.com'" >> /etc/hosts

# Add the jobs to cron
RUN crontab -l | { cat; echo "00 1 * * * rsync -aqe '"ssh -p 22"' --delete --exclude '*.json' ${RSYNC_USER}@${RMT_REMOTE_HOST}:/var/lib/rmt/public/* /var/lib/rmt/public/"; } | crontab -
RUN crontab -l | { cat; echo "30 4 * * * rmt-cli import repos /var/lib/rmt/public/repo/"; } | crontab -
RUN crontab -l | { cat; echo "00 00 1 * * rmt-cli systems list --all > ~/systems_'$(date +"%d-%m-%Y")'.txt && rsync -aqze '"ssh -p 22"' --remove-source-files ~/systems* ${RSYNC_USER}@${RMT_REMOTE_HOST}:~"; } | crontab -
