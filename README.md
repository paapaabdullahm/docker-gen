## **Docker Gen**

Template generation via docker container metadata. It can be used to generate various kinds of files for:
* **Centralized logging** - [fluentd](https://github.com/jwilder/docker-gen/blob/master/templates/fluentd.conf.tmpl), logstash or other centralized logging tools that tail the containers JSON log file or files within the container.
* **Log Rotation** - [logrotate](https://github.com/jwilder/docker-gen/blob/master/templates/logrotate.tmpl) files to rotate container JSON log files
* **Reverse Proxy Configs** - [nginx](https://github.com/jwilder/docker-gen/blob/master/templates/nginx.tmpl), [haproxy](https://github.com/jwilder/docker-discover), etc. reverse proxy configs to route requests from the host to containers
* **Service Discovery** - Scripts (python, bash, etc..) to register containers within [etcd](https://github.com/jwilder/docker-register), hipache, etc..

