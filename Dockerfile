FROM opensuse/leap:15.4

RUN zypper --non-interactive install --no-recommends \
        timezone wget gcc-c++ libffi-devel git-core zlib-devel \
        libxml2-devel libxslt-devel cron libmariadb-devel mariadb-client \
        vim ruby2.5 ruby2.5-devel ruby2.5-rubygem-bundler SUSEConnect && \
    zypper --non-interactive install -t pattern devel_basis && \
    update-alternatives --install /usr/bin/bundle bundle /usr/bin/bundle.ruby2.5 5 && \
    update-alternatives --install /usr/bin/bundler bundler /usr/bin/bundler.ruby2.5 5

RUN zypper --non-interactive install --no-recommends \
        rmt-server rmt-server-config

RUN echo "127.0.0.2       suse.com scc.suse.com" >> /etc/hosts


WORKDIR /srv/www/rmt/

EXPOSE 4224

CMD ["/usr/share/rmt/bin/rails", "server", "-e", "production", "-b", "127.0.0.1", "-p", "4224"]
