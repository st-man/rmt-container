# Install 
## Create Certificate
#### Change hostname and ip_address to your data.
```bash
sudo export CA_PWD="SuSE1@34"
sudo export hostname=192.168.13.1.sslip.io
sudo export ip_address=192.168.13.1
sudo openssl genrsa -aes256 -passout env:CA_PWD -out ./ssl/rmt-ca.key 2048
sudo openssl req -x509 -new -nodes -key ./ssl/rmt-ca.key -sha256 -days 1825 -out ./ssl/rmt-ca.crt -passin env:CA_PWD -config ./ssl/rmt-ca.cnf
sudo openssl genrsa -out ./ssl/rmt-server.key 2048
sudo openssl req -new -key ./ssl/rmt-server.key -out ./ssl/rmt-server.csr -config ./ssl/rmt-server.cnf
sudo openssl x509 -req -in ./ssl/rmt-server.csr -out ./ssl/rmt-server.crt -CA ./ssl/rmt-ca.crt -CAkey ./ssl/rmt-ca.key -passin env:CA_PWD -days 1825 -sha256 -CAcreateserial -extensions v3_server_sign -extfile ./ssl/rmt-server.cnf
sudo chmod 0600 ./ssl/*
sudo chmod 0640 ./ssl/rmt-ca.crt
sudo chown root:root ./ssl/*
```
## Start services
```bash
zypper in -y jq docker python3-docker-compose
echo "$(jq '. += {"bip": "10.10.0.1/16", "default-address-pools": [{ "base": "10.11.0.0/16", "size": 24 }]}' /etc/docker/daemon.json)" > /etc/docker/daemon.json
docker-compose build
docker-compose up -d
docker-compose down -v
```
# Создание файлов для системы обновления RMT.

Для обновления RMT в Air Gap требуются следующие файлы:

./organizations_orders.json - пустой
./organizations_products.json - данные по продуктам перечисленных в organizations_subscriptions.json
./organizations_products_unscoped.json - данные по всем продуктам, для всех пользователей одинаковые
./organizations_repositories.json - список репозиториев с токенами
./organizations_subscriptions.json - информация по подпискам
./repos.json - спискок репозиториев с токенами, может быть пустой
./suma/product_tree.json - дерево продуктов - доступно совободно, для всех пользователей одинаковое

Скрипт make_db.py из файла organizations_products_unscoped.json создает промежуточную базу данных (продукты, репозитории, и т.д.).
Скрипт make_products-v3.py из файла organizations_subscriptions.json и промежуточной базы создает файл organizations_products.json

## Структура промежуточной базы данных

Extensions - все являются продуктами

* products
	* id PRIMARY KEY
	* name
	* identifier
	* former_identifier
	* version
	* release_type
	* arch
	* friendly_name
	* friendly_version
	* product_class
	* cpe
	* free
	* description
	* release_stage
	* eula_url
	* product_type
	* shortname
	
* repositories
	* id PRIMARY KEY
	* name
	* url
	* distro_target
	* description

* repositories_products
	* repository_id FOREIGN KEY
	* product_id FOREIGN KEY
	* enabled
	* autorefresh
	* installer_updates

* extensions_products
	* extension_id FOREIGN KEY
	* product_id FOREIGN KEY
	* recommended
	* migration_extra

* predecessors
	* predecessor_id FOREIGN KEY
	* product_id FOREIGN KEY

* online_predecessors
	* online_predecessor_id FOREIGN KEY
	* product_id FOREIGN KEY
	
* offline_predecessors
	* offline_predecessor_id FOREIGN KEY
	* product_id FOREIGN KEY
