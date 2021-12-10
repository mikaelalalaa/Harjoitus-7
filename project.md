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

Muokkauksien jälkeen otin ne käyttöön komennolla 

```
sudo salt '*' state.apply sshd
```

Kuten kuvasta näkyy muutokset tuli onnistuneestin käyttöön. 

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

## Tietokannan ja käyttäjän luominen

Tietokanna luomisen aloitin kirjautumalla mysql, komennolla `mysql -u root -p` *(eli pääkäyttäjällä)*. Loin uuden teitokannan komennolla `CREATE DATABASE wordpress`, jonka jälkeen loin sitä varten käyttäjän `wpusr` jolle annoin kaikki oikeudet vasta luotuun tietokantaan komennot oli:

```
CREATE USER 'wpusr'@'localhost' IDENTIFIED BY 'password';
&
GRANT ALL ON wordpress.* TO 'wpusr'@'localhost' IDENTIFIED BY 'passwd';
&
FLUSH PRIVILEGES;
```

Vielä visuaalisestin miltä tietokanna luominen näyttää 

![image](https://user-images.githubusercontent.com/93308960/145247868-8bec645b-b06c-41c8-b1ef-a2687947a827.png)

#  Wordpress ja Apache2 

Loin uuden init.sls tiedoston wordpressiä varten, jossa ladataan/puretaan wordpress tiedosto ja annetaan oikeudet tiedostoille.

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

Ajoin komennon 
```
sudo salt '*' state.apply wordpress 
```
joka ensimmäinen tulos ei onnistunut, koska tiedostossa oli kirjoitus virhe. Korjasin virheen ja halutut muutokset otettiin onnistuneesti käyttöön  

![image](https://user-images.githubusercontent.com/93308960/145493499-0514f5f7-98dc-4fb0-a2ff-2841f6d5c8a2.png)

Kopioitiin wp-config.php tiedosto /srv/salt/wordpress hakemistoon, muokattiin tiedostoa lisäämällä aijemin luotu tietokannan tiedot:

```
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpredd' );
/** MySQL database username */
define( 'DB_USER', 'wpudr' );
/** MySQL database password */
define( 'DB_PASSWORD', 'passwd' );
/** MySQL hostname */
define( 'DB_HOST', 'localhost' );
```

Koska haluttiin että muutokset tulevat voimaan aijettiin komento `sudo salt '*' state.apply wordpress` uudestaan. Muutokset otettiin onnistuneestin käyttöön.

![image](https://user-images.githubusercontent.com/93308960/145494320-10947db0-e67a-4ec8-a0b2-a63c46275df9.png)




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




