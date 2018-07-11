## **Docker Gen**

Template generation via docker container metadata. It can be used to generate various kinds of files for:
* **Centralized logging** - [fluentd](https://github.com/jwilder/docker-gen/blob/master/templates/fluentd.conf.tmpl), logstash or other centralized logging tools that tail the containers JSON log file or files within the container.
* **Log Rotation** - [logrotate](https://github.com/jwilder/docker-gen/blob/master/templates/logrotate.tmpl) files to rotate container JSON log files
* **Reverse Proxy Configs** - [nginx](https://github.com/jwilder/docker-gen/blob/master/templates/nginx.tmpl), [haproxy](https://github.com/jwilder/docker-discover), etc. reverse proxy configs to route requests from the host to containers
* **Service Discovery** - Scripts (python, bash, etc..) to register containers within [etcd](https://github.com/jwilder/docker-register), hipache, etc..

&nbsp;
## Separate Container Install

* #### Start nginx with a shared volume:
  ```shell
  $ docker run -d -p 80:80 --name nginx -v /tmp/nginx:/etc/nginx/conf.d -t pam79/nginx
  ```

&nbsp;
* #### Fetch the template and start the docker-gen container with the shared volume:
  ```shell
  $ mkdir -p /tmp/templates && cd /tmp/templates
  ```
  ```shell
  $ curl -o nginx.tmpl https://raw.githubusercontent.com/jwilder/docker-gen/master/templates/nginx.tmpl
  ```
  ```shell
  $ docker run -d --name nginx-gen --volumes-from nginx \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    -v /tmp/templates:/etc/docker-gen/templates \
    -t pam79/docker-gen -notify-sighup nginx -watch -only-exposed \
       /etc/docker-gen/templates/nginx.tmpl \
       /etc/nginx/conf.d/default.conf
  ```

&nbsp;
## Add docker-gen command via .bashrc or .zshrc

```shell
$ vim .bashrc
```
```shell
docker-gen() { docker run -it --rm pam79/docker-gen "$@"; }
```

&nbsp;
## Access help options

```shell
$ docker-gen
```
```sh
Usage: docker-gen [options] template [dest]

Generate files from docker container meta-data

Options:
  -config value
      config files with template directives. Config files will be merged if this option is specified multiple times. (default [])
  -endpoint string
      docker api endpoint (tcp|unix://..). Default unix:///var/run/docker.sock
  -interval int
      notify command interval (secs)
  -keep-blank-lines
      keep blank lines in the output file
  -notify restart xyz
      run command after template is regenerated (e.g restart xyz)
  -notify-output
      log the output(stdout/stderr) of notify command
  -notify-sighup container-ID
      send HUP signal to container.  Equivalent to 'docker kill -s HUP container-ID'
  -only-exposed
      only include containers with exposed ports
  -only-published
      only include containers with published ports (implies -only-exposed)
  -include-stopped
      include stopped containers
  -tlscacert string
      path to TLS CA certificate file (default "/Users/jason/.docker/machine/machines/default/ca.pem")
  -tlscert string
      path to TLS client certificate file (default "/Users/jason/.docker/machine/machines/default/cert.pem")
  -tlskey string
      path to TLS client key file (default "/Users/jason/.docker/machine/machines/default/key.pem")
  -tlsverify
      verify docker daemon's TLS certificate (default true)
  -version
      show version
  -watch
      watch for container changes
  -wait
      minimum (and/or maximum) duration to wait after each container change before triggering

Arguments:
  template - path to a template to generate
  dest - path to a write the template. If not specified, STDOUT is used

Environment Variables:
  DOCKER_HOST - default value for -endpoint
  DOCKER_CERT_PATH - directory path containing key.pem, cert.pm and ca.pem
  DOCKER_TLS_VERIFY - enable client TLS verification]
```

&nbsp;
## Configuration file

Using the `-config` flag from above you can tell docker-gen to use the specified config file instead of command-line options. Multiple templates can be defined and they will be executed in the order that they appear in the config file.

An example configuration file, **docker-gen.cfg** can be found in the [examples](https://github.com/jwilder/docker-gen/tree/master/examples) folder.

&nbsp;
## Configuration File Syntax

```sh
[[config]]
Starts a configuration section

dest = "path/to/a/file"
path to a write the template. If not specified, STDOUT is used

notifycmd = "/etc/init.d/foo reload"
run command after template is regenerated (e.g restart xyz)

onlyexposed = true
only include containers with exposed ports

template = "/path/to/a/template/file.tmpl"
path to a template to generate

watch = true
watch for container changes

wait = "500ms:2s"
debounce changes with a min:max duration. Only applicable if watch = true


[config.NotifyContainers]
Starts a notify container section

containername = 1
container name followed by the signal to send

container_id = 1
or the container id can be used followed by the signal to send
Putting it all together here is an example configuration file.

[[config]]
template = "/etc/nginx/nginx.conf.tmpl"
dest = "/etc/nginx/sites-available/default"
onlyexposed = true
notifycmd = "/etc/init.d/nginx reload"

[[config]]
template = "/etc/logrotate.conf.tmpl"
dest = "/etc/logrotate.d/docker"
watch = true

[[config]]
template = "/etc/docker-gen/templates/nginx.tmpl"
dest = "/etc/nginx/conf.d/default.conf"
watch = true
wait = "500ms:2s"

[config.NotifyContainers]
nginx = 1  # 1 is a signal number to be sent; here SIGHUP
e75a60548dc9 = 1  # a key can be either container name (nginx) or ID
```

&nbsp;
## Example Usage

* #### Reverse Proxy via Docker Compose (recommended)

  Create external network for the reverse proxy
  ```shell
  $ docker network create -d bridge proxy-tier
  ```

  &nbsp;
  Create a directory for the proxy resource and change to it
  ```shell
  $ mkdir -p Projects/reverse-proxy && cd Projects/reverse-proxy
  ```

  &nbsp;
  Download the latest `nginx.tmpl` template file
  ```shell
  $ curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > ./nginx.tmpl
  ```

  &nbsp;
  Create the reverse-proxy docker-compose file
  ```shell
  $ vim docker-compose.yml
  ```

  &nbsp;
  Add the following contents to it
  ```shell
  version: '2.1'

  services:

    proxy-gen:
      image: pam79/docker-gen
      container_name: proxy-gen
      volumes_from:
        - proxy
      volumes:
        - /var/run/docker.sock:/tmp/docker.sock:ro
        - ./nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro
      command: -watch -notify-sighup=proxy -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
      tty: true
      stdin_open: true
      depends_on:
        - proxy
      restart: always

    proxy:
      image: pam79/nginx
      container_name: proxy
      volumes:
        - /etc/nginx/conf.d
        - /etc/nginx/vhost.d
        - /usr/share/nginx/html
        - ./certs:/etc/nginx/certs:ro
      ports:
        - "80:80"
        - "443:443"
      tty: true
      stdin_open: true
      networks:
        - default
      restart: always

  networks:
    default:
      external:
        name: proxy-tier
  ```

  &nbsp;
  For SSL to work for this setup in development, you should create a self-signed certificate, and locally trust it. To help speed up this process, consider using the following script: https://github.com/pam79/ssl-gen

  &nbsp;
  Finally, start the reverse-proxy
  ```shell
  $ docker-compose up -d
  ```

  &nbsp;
  Also, if you plan to use this setup in production, don't forget to add the following service to it to help obtain SSL/TLS certificate automatically from letsencrypt:

  ```shell
  letsencrypt:
    image: pam79/letsencrypt
    container_name: letsencrypt
    environment:
      - NGINX_DOCKER_GEN_CONTAINER=proxy-gen
    volumes_from:
      - proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./certs:/etc/nginx/certs:rw
    depends_on:
      - proxy-gen
    restart: always
  ```

&nbsp;
* #### Fluentd Log Management

  This template generate a fluentd.conf file used by fluentd. It would then ship log files off the host.

  ```shell
  $ docker-gen -watch -notify "restart fluentd" templates/fluentd.tmpl /etc/fluent/fluent.conf
  ```

&nbsp;
* #### Service Discovery in Etcd

  This template is an example of generating a script that is then executed. This template generates a python script that is then executed which register containers in Etcd using its HTTP API.

  ```shell
  $ docker-gen -notify "/bin/bash /tmp/etcd.sh" -interval 10 templates/etcd.tmpl /tmp/etcd.sh
  ```
