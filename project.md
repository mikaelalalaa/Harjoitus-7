# Alku

Loin kaksi virtuaali konetta asensin toiseen master ja toiseen minion, käyttöjärjestelmänä toimi Ubunut server 20.4 LTS. 

Tämän jälkeen halusin ottaa putty ohjelmaa yhetyden joten piti asentaa `openssh-server`, halusin myös samalla konfiguroida eri portin ja banner teksin. Aluksi asensin ssh komennolla `sudo apt-get install openssh-server`, sitten loin banner.txt tiedoston `/etc/ssh` hakemistoon, kopioin banner ja sshd_config tiedostot srv/salt/sshd hakemistoon.

Loin *init.sls* tiedoston srv/salt/sshd hakemistoon jonne kirjoitin haluttavat salt formulat. Muokkasin sshd_config tiedostoa ja lisäsin sinne kohdan `Port 2222`, kun ottaa yhetyttä nii ssh käyttää porttia 2222

```
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

``` 

Muutoksien jälkeen otin ne käyttöön komennolla 

```
sudo salt '*' state.apply sshd
```

Kuten kuvasta näkyy muutokset tuli onnistuneestin käyttöön

![image](https://user-images.githubusercontent.com/93308960/145212674-1f983697-2db4-4b22-9fa4-d265d44061ff.png)

Toisesta kuvasta vielä näkyy että yhdistäminen putty ohjelmaan onnistui ja samalla myös banner teksti näkyy. 

![image](https://user-images.githubusercontent.com/93308960/145214879-5a5f61f3-aef4-417e-8e73-63c69de144d3.png)

SSH asennuksien jälkeen tein uuden salt moduulin josta pystyisin yhdellä kertaa asentamaan kaikki mahdolliset sovellukset joita tulisin käyttämään projektin aikana.

```
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

```

Ajoin komennon 

```
sudo salt '*' state.apply allapps
```

Asennus oli onnistunut. Paketit jotka olivat uusia asentui ilman ongelmia ja jotkut paketit olivatkin jo asennettu.

![image](https://user-images.githubusercontent.com/93308960/145233892-e9a7e336-c999-49ca-961e-a28c5b334c6a.png)

## Tietokannan luominen

Tietokanna luomisen aloitin kirjautumalla mysql, komennolla `mysql -u root -p` *(eli pääkäyttäjällä)*. Loin uuden teitokannan komennolla `CREATE DATABASE wordpress`, jonka jälkeen loin sitä varten käyttäjän `wpusr` jolle annoin kaikki oikeudet vasta luotuun tietokantaan komennot oli:

```

```


# Apache2 ja Wordpress 



```

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

```




```
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
```
