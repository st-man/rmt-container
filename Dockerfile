FROM registry.opensuse.org/opensuse/rmt-server:2.9

# Add package for rsync
RUN zypper --non-interactive install --no-recommends rsync openssh-clients cronie

#RUN echo "127.0.0.2       suse.com scc.suse.com" >> /etc/hosts

RUN crontab -l | { cat; echo "00 01 * * * rsync -aqe "ssh -p 22" --delete --exclude '*.json' UC2622847@172.17.182.147:/var/lib/rmt/public/* /var/lib/rmt/public/"; } | crontab -
RUN crontab -l | { cat; echo "00 04 * * * docker-compose exec rmt rmt-cli import repos /var/lib/rmt/public/repo/"; } | crontab -

