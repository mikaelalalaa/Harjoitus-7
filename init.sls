all the apps:
  pkg.installed:
    - pkgs:
      - apache2
      - tree
      - net-tools
      - mariadb-server
      - mariadb-client
      - php
      - php-mysql
      - php-bcmath
      - php-curl
      - php-imagick
      - php-intl
      - php-json
      - php-mbstring
      - php-xml
      - php-zip

openssh-server:
  pkg.installed

/etc/ssh/sshd_config:
  file.managed:
    - source: salt://sshd/sshd_config

banner:
  file.managed:
    - source: salt://sshd/banner.txt
    - name: /etc/ssh/banner.txt

sshd:
  service.running:
    - enable: True
    - watch:
      - file: /etc/ssh/sshd_config


apache2:
  pkg.installed

/etc/apache2/sites-available/000-default.conf:
  file.managed:
    - source: salt://apache2/000-default.conf

restart:
  service.running:
    - name: apache2
    - watch:
      - /etc/apache2/sites-available/000-default.conf


##wp install source https://gist.github.com/hbokh/944987bb7f34dc38767830b882364e3e

get_wordpress:
  cmd.run:
    - name: 'wget -q -O - http://wordpress.org/latest.tar.gz | tar zxf - '
    - cwd: /var/www
    - creates: /var/www/wordpress/index.php
    - runas: root

/var/www/wordpress/wp-config.php:
  file.managed:
    - source: salt://wordpress/wp-config.php
    - user: www-data
    - group: www-data

/var/www/wordpress:
  file.directory:
    - user: www-data
    - group: www-data
    - dir_mode: 775
    - file_mode: 664
    - recurse:
      - user
      - group
      - mode
