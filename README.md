
## Установка сервера централизованных обновлений

Системе требуется доступ к хосту [updates.supportlinux.su](updates.supportlinux.su) по **TCP**, порт **44322**.
Необходимо указать переменные  **RSYNC_USER** и **USER_PASS** в файле окружения.
Данные предоставляются при передаче системы.

## 1. Устанавливаем любой linux с docker-compose.
Рекомендованные (проверенные) дистрибутивы: openSUSE Leap 15.x, opensuse Tumbleweed, SLES 15.3+
### 1.1 обязательные пакеты
* docker-composer
или
* python3-docker-compose

Пример для opensuse:15.4
```bash
zypper addrepo https://download.opensuse.org/repositories/home:ojkastl_buildservice:docker_compose_etc/openSUSE_Tumbleweed/home:ojkastl_buildservice:docker_compose_etc.repo
zypper refresh
zypper install docker-compose
```

### 1.2 файловая система
* ext4, раздел /, размер зависит от количества подписок и варьируется для продуктов SLES, в среднем, от 150 до 500 Gb (примерно 50Gb на продукт)

### 1.3 имя хоста
 Имя хоста дожно содержать FQDN (пример: rmtairgap.acme.com)
```bash
hostnamectl - ЧТО-ТО НАДО НАПИСАТЬ
```
## 2. Настройка хоста Docker
### 2.1 Разрешить и запустить сервис docker
```bash 
 sudo systemctl enable docker --now
```
## 3. Запуск системы RMT
### 3.1 получить из git (или развернуть из предоставленного архива файлы настройки контейнеров)
```bash
 cd
 git clone https://github.com/st-man/rmt-container
 cd rmt-container
```
### 3.2 Изменить (ОБЯЗАТЕЛЬНО) файл .env
```bash
RSYNC_USER="ИМЯ ПОЛЬЗОВАТЕЛЯ ДЛЯ СИНХРОНИЗАЦИИ" # Example RSYNC_USER=UC2724859
USER_PASS="ПАРОЛЬ ПОЛЬЗОВАТЕЛЯ ДЛЯ СИНХРОНИЗАЦИИ" # Example USER_PASS=6A9b500j
```
### 3.3 Заполнить правильными данными файл certgen.sh (значениями локальной системы)
```bash
export CA_PWD="PASSWORD" (например, export CA_PWD="_rmt")
```
### 3.4 Создать сертификаты для работы RMT
Выполнить скрипт создания сертификатов
```
sh certgen.sh
```
в результате работы в каталоге ./ssl должны быть файлы:
* rmt-ca.cnf
* rmt-ca.crt
* rmt-ca.key
* rmt-ca.srl
* rmt-server.cnf
* rmt-server.crt
* rmt-server.csr
* rmt-server.key
* tls.crt
* tls.key

### 3.5 Запустить контейнеры
при первом запуске образы контейнеров будут скачаны с [registry.opensuse.org/opensuse](registry.opensuse.org/opensuse), при необходимости, можно организовать локальный registry
```bash
 docker-compose up -d
```
При запуске контейнер rmt проверяет наличие синхронизированных пакетов с удаленного RMT, поэтому при первом запуске может пройти много времени, прежде чем контейнер будет готов к работе. Посмотреть журнал работы контейнера (50 строк):
```bash
docker logs --tail=50 rmt-container-rmt-1 
```
### 3.6 Проверить, что контейнеры работают
```bash
docker-compose ps
------------
NAME                    COMMAND                  SERVICE             STATUS              PORTS
rmt-container-db-1      "/entrypoint.sh mysq…"   db                  running             3306/tcp
rmt-container-nginx-1   "/usr/local/bin/entr…"   nginx               running             0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp
rmt-container-rmt-1     "/bin/bash /usr/loca…"   rmt                 running   
------------
```
### 3.7 Проверить наполнение RMT данными
```bash
docker-compose exec rmt rmt-cli products list -all
```
в случае отсутствия списка продуктов, проверить каталог **./public/repo/SUSE** на наличие пакетов *.rpm, если отсутствуют, подождать автоматической синхронизации или провести ее вручную, см. ниже

### 3.8 Разрешить (enable) необходимые продукты
(в примере 2136 - SLES for SAP) и репозитории (посмотреть список доступных продуктов: docker-compose exec rmt rmt-cli products list --all)
```bash
docker-compose exec rmt rmt-cli products enable 2136
```
Проверить включенные продукты
```bash
docker-compose exec rmt rmt-cli products list
```
## 4. Регистрация систем в RMT
[Ссылка на документацию](https://documentation.suse.com/sles/15-SP4/html/SLES-all/cha-rmt-client.html#sec-rmt-client-clientsetupscript)

### 4.1 Зайти в подключаемую систему под root
```bash
ssh root@${SYSTEM_TO_BE_REGISTER}
```
### 4.2 Скачать скрипт на систему
```bash
curl http://${RMT_SERVER}/tools/rmt-client-setup --output rmt-client-setup
```
### 4.3 Выполнить скрипт для регистрации системы в RMT
сертификаты будут импортированы в доверенное хранилище
```bash
sh rmt-client-setup https://${RMT_SERVER}/
```
-------------------------------------------
## 5. Дополнительные действия (root):
```bash
cd ~/rmt-container
```
### 5.1 При необходимости, можно синхронизировать пакеты вручную
в первый раз может занять много времени
```bash
docker-compose exec rmt rsync -ave "ssh -p 43322" --delete --exclude '*.json' ${RSYNC_USER}@${RMT_REMOTE_HOST}:/var/lib/rmt/public/* /var/lib/rmt/public (чтобы отключить verbose, используйте ключ -aqe вместо -ave)
```

### 5.2 В случае изменения добавления посписки на продукт
при необходимости обновить список продуктов вручную:
```bash
docker-compose exec rmt rsync -e "ssh -p 44322" ${RSYNC_USER}@${RMT_REMOTE_HOST}:~/rmt/* ~/rmt-container/public/repo/
docker-compose exec rmt chown -R _rmt:nginx /var/lib/rmt/public/
```
### 5.3 Импортировтаь новые данные в RMT
```bash
docker-compose exec rmt rmt-cli import data /var/lib/rmt/public/repo/
```
### 5.4 После синхронизации пакетов вручную
можно дождаться работы по расписанию, добавить новый продукт (репозиторий) в RMT
```bash
docker-compose exec rmt rsync -ave "ssh -p 43322" --delete --exclude '*.json' ${RSYNC_USER}@${RMT_REMOTE_HOST}:/var/lib/rmt/public/* /var/lib/rmt/public
```
чтобы отключить verbose, используйте ключ -aqe вместо -ave
```bash
docker-compose exec rmt rmt-cli products enable ${PRODUCT_ID)
```

##### [suse.ru/support](https://suse.ru/support)