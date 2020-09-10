# Repository Mirroring Tool for Cloud service providers

This tool allows you to mirror RPM repositories in your own private network.
Organization (mirroring) credentials are required to mirror SUSE repositories.

End-user documentation can be found in [RMT Guide](https://documentation.suse.com/sles/15-SP1/html/SLES-all/book-rmt.html).

### Running with docker-compose
### Prerequisits:
* SLES15SP1 or higher
* docker engine installed e.g. zypper in -y docker
* download and install docker-compose:
    https://docs.docker.com/compose/install/
    ```
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    docker-compose --version
    
    ```
  __Cautious:__
  Do not install docker-compose from packagehub for SLES15SP1 as the docker-compose there needs python2 and not python3 which is installed on SLES15 and higher.
 
 __Remarks:__
 * When mariadb container starts for the first time it will init db and this process takes some time. To avoid db connect failure of rmt container a modified entrypoint script will sleep for 20 seconds followed by a db connect test. If db connect return is successful then the script will continue. __rmt-start.sh__
 * feel free to change the sleep time duration for your need.
 * To keep mariadb init fast the below env parameter is in place and skip timezone table load.
 ```environment:
      - MYSQL_INITDB_SKIP_TZINFO=1
```
* 


__In order to run the application locally using docker-compose:__

1. Copy `.env.example` file to `.env`;
2. Add your organization credentials to `.env` file. Mirroring credentials can be obtained from the [SUSE Customer Center](https://scc.suse.com/organization);
3. Start the containers by running `docker-compose up`. Running `docker-compose up -d` will start the containers in the background;
4. Execute commands in the container, e.g.:
    ```bash
    docker-compose exec rmt rmt-cli repos --help
    ```
    Alternatively, running `docker-compose exec rmt bash` will start the shell inside the container.
5. The web server will be accessible at [http://your-host-fqdn-or-ip](http://your-host-fqdn-or-ip/), this URL can be used for registering clients.
6. To test if repo is accessible open this url: http://your-host-fqdn-or-ip/repo you should see directory browsing which is empty as long as you have not synced any repo via scc.suse.com

## RMT and SMT

RMT is replacing some functionality of [SMT](https://github.com/SUSE/smt). Following table outlines differences and similarities between the two tools. Last SLE version where SMT is available is 12. From version 15 onward only RMT is offered.

| Feature/Tech      | SMT           | RMT           |
|-------------------|:-------------:|:-------------:|
|Available on SLES11|:heavy_check_mark:|:x:|
|Available on SLES12|:heavy_check_mark:|:x:|
|Available on SLES15|:x:|:heavy_check_mark:|
|Sync products data from SCC|:heavy_check_mark:|:heavy_check_mark:|
|Mirror RPMs from repositories|:heavy_check_mark:|:heavy_check_mark:|
|Selective mirroring(which products to mirror)|:heavy_check_mark:|:heavy_check_mark:|
|Serve RPMs via http|:heavy_check_mark:|:heavy_check_mark:|
|Registration of SLE 15 systems|:heavy_check_mark:|:heavy_check_mark:|
|Registration of SLE 12 systems|:heavy_check_mark:|:heavy_check_mark:|
|Registration of SLE 11 systems|:heavy_check_mark:|:x:|
|Migration support SLE 12 > 15|:heavy_check_mark:|:heavy_check_mark:|
|Staging repositories|:heavy_check_mark:|:x:<sup>[1](#staging)</sup>|
|Air gap sync/mirroring for secure environments|:heavy_check_mark:|:heavy_check_mark:|
|NTLM Proxy support|:heavy_check_mark:|:heavy_check_mark:|
|Custom repositories|:heavy_check_mark:|:heavy_check_mark:|
|YaST installation wizard|:heavy_check_mark:|:heavy_check_mark:|
|YaST management wizard|:heavy_check_mark:|:x:|
|Client management|:heavy_check_mark:|:x:|
|Red Hat support ([Expanded Support](https://www.suse.com/products/expandedsupport/))|:heavy_check_mark:|:x:<sup>[2](#res)</sup>|
|Files deduplication|:heavy_check_mark:|:heavy_check_mark:|
|Data transfer from SMT to RMT|-|:heavy_check_mark:|
|Transfer registration data to SCC|:heavy_check_mark:|:x:<sup>[3](#regup)</sup>|
|Reporting|:heavy_check_mark:|:x:|
|Custom TLS certificates for web-server|:heavy_check_mark:|:heavy_check_mark:|
|Webserver|Apache2|Nginx|
|Database|MariaDB|MariaDB|
|Platform|Perl|Ruby|

<a name="staging">1</a>: Functionality is offered by [SUSE Manager](https://www.suse.com/documentation/suse-best-practices/susemanager/data/susemanager.html)  
<a name="res">2</a>: RES support is planned for SLES15 SP1  
<a name="regup">3</a>: Registration data transfer to SCC is planned for SLES15 SP2


Feedback is always welcome!
