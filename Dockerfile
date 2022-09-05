FROM opensuse/tumbleweed

RUN zypper --non-interactive install --no-recommends \
        openssh-clients rsync
        
