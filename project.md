# Alku

Loin virtuaali koneen, asensin salt master ja minion ohjelman, käyttöjärjestelmänä toimi Ubuntu server 20.4 LTS. 

 Salt minion ja master asennus tapahtui komennoilla 

```
sudo apt-get install salt-master
&
sudo apt-get install salt-minion
```

Asennuksien jälkeen muokkasin `etc/salt/minion` tiedostoa lisäämällä master koneen ip-osoitteen *(192.168..)* ja minion koneen nimen *(id: mini)*, sitten uudelleen käynnistin minion koneen komennolla `sudo systemctl restart salt-minion`. Minion lähettää avaimen masteri koneelle, tämän avaimen hyväksyin komennolla `sudo salt-key -A`. Testasin yhteyttä komennolla `sudo salt '*' test.ping`. Tuloksena tuli 'true' kommunikaatio onnistuu.

![image](https://user-images.githubusercontent.com/93308960/145733598-8a6ca319-f2bf-4ba4-bf84-d6e72accfbb8.png)


Tämän jälkeen halusin ottaa putty ohjelmalla yhteyden joten piti asentaa `openssh-server`, halusin myös samalla konfiguroida eri portin ja banner tekstin. Aluksi asensin ssh komennolla `sudo apt-get install openssh-server`, sitten loin banner.txt tiedoston `/etc/ssh` hakemistoon, kopioin banner ja sshd_config tiedostot srv/salt/sshd hakemistoon.

Loin *init.sls* tiedoston srv/salt/sshd hakemistoon jonne kirjoitin haluttavat salt formulat. Muokkasin sshd_config tiedostoa ja lisäsin sinne kohdan `Port 2222`, kun ottaa yhetyttä niin ssh käyttää porttia 2222

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

Kuten kuvasta näkyy muutokset tulivat onnistuneesti käyttöön. 

![image](https://user-images.githubusercontent.com/93308960/145212674-1f983697-2db4-4b22-9fa4-d265d44061ff.png)

Tässä vielä näkyy että yhdistäminen putty ohjelmaan onnistui ja banner teksti näkyy.

![image](https://user-images.githubusercontent.com/93308960/145214879-5a5f61f3-aef4-417e-8e73-63c69de144d3.png)

SSH asennuksien jälkeen tein uuden salt moduulin jotta pystyisin yhdellä kertaa asentamaan kaikki mahdolliset sovellukset joita tulisin käyttämään projektin aikana.

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

Ainoa mitä en saaut automatisoitua oli tietokannan luominen ja siihen käyttäjää, joten tein sen käsin.
Tietokannan luomisen aloitin kirjautumalla mysql, komennolla `mysql -u root -p` *(eli pääkäyttäjällä)*. Loin uuden tietokannan komennolla `CREATE DATABASE wordpress`, jonka jälkeen loin sitä varten käyttäjän `wpusr` jolle annoin kaikki oikeudet, vasta luotuun tietokantaan. Komentoina toimi:

```
CREATE USER 'wpusr'@'localhost' IDENTIFIED BY 'password';
&
GRANT ALL ON wordpress.* TO 'wpusr'@'localhost' IDENTIFIED BY 'passwd';
&
FLUSH PRIVILEGES;
```

Vielä visuaalisestin miltä tietokanna luominen näyttää 

![image](https://user-images.githubusercontent.com/93308960/145247868-8bec645b-b06c-41c8-b1ef-a2687947a827.png)

## Wordpress ja Apache2 

Loin uuden init.sls tiedoston wordpressiä varten, jossa ladataan ja puretaan wordpress tiedosto ja annetaan oikeudet tiedostoille.
*Wordpress tulee automaattisesti pakattuna tiedostona ja se pitää purkaa ennen käyttöä*

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
Ensimmäinen kerta ei onnistunut, koska tiedostossa oli kirjoitus virhe. Korjasin virheen ja ajoin pari kertaa komennon jotta tulos olisi idempotentti, joka onnistui. 

![image](https://user-images.githubusercontent.com/93308960/145493499-0514f5f7-98dc-4fb0-a2ff-2841f6d5c8a2.png)

Kopioitiin wp-config.php tiedosto /srv/salt/wordpress hakemistoon, katsottiin että kopioitu tiedosto oli mennyt haluttuun hakemistoon komennolla `tree`

![image](https://user-images.githubusercontent.com/93308960/145733210-3c4385d5-9412-464e-984d-ea505c6e0882.png)

Sen jälkee muokattiin config tiedostoa lisäämällä aijemin luotu tietokannan tiedot:

```
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );
/** MySQL database username */
define( 'DB_USER', 'wpusr' );
/** MySQL database password */
define( 'DB_PASSWORD', 'passwd' );
/** MySQL hostname */
define( 'DB_HOST', 'localhost' );
```

Koska haluttiin että muutokset tulevat voimaan ajettiin komento `sudo salt '*' state.apply wordpress` uudestaan. Muutokset otettiin onnistuneesti käyttöön.

![image](https://user-images.githubusercontent.com/93308960/145494320-10947db0-e67a-4ec8-a0b2-a63c46275df9.png)

Ennen kuin tehtiin mitään muutoksia apacheen niin katsottiin onko sovellus käynnissä ja saadaanko aloitus sivu näkymään selaimeen. Apachen tila saatiin katsottua komennolla `sudo systemctl status apache2` ja sivu katsottinn laittamalla ip-osoite selaimeen. Kuvasta näkyy molemmat onnistui.

![image](https://user-images.githubusercontent.com/93308960/145219802-50050723-c2e4-485c-80e0-df7adbc3bab1.png)

Sitten alettiin konfiguroimaan apache2 jotta saataisiin wordpress pystyyn. Aloitettiin kopioimalla 000-default.conf tiedosto /srv/salt/apache2 hakemistoon ja luomalla init.sls tiedosto. Muokattiin conf tiedostoa ja vaihdettiin DocumentRoot ja ServerAdmin sopimaan wordpressin tietoja. Eli vaihdettiin apachen oma oletus sivu hakemisto wordpressin hakemistoon eli `DocumentRoot /var/www/html --> DocumentRoot /var/www/wordpress` ja vaihdettiin apache ServerAdmin wordpressin eli ` ServerAdmin webmaster@localhost -->  ServerAdmin wpusr@localhost`.

conf tiedoston jälkeen muokattiin init.sls tiedostoa, jotta saadaan varmistettua että apache2 on asentunut, sekä conf tiedoston muutokset ovat tulleet voimaan ja myös että apache on käynnissä.

Joten tiedoston sisältö näytti tältä:

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

Ajettiin se komennolla 

```
sudo salt '*' state.apply apache2
```

Kaikki muutokset tulivat onnistuneesti voimaan koska wordpressin asennus sivu tuli näkyviin selaimeen. Sitten alettiin luomaan käyttäjää ja muokkaamaan sivua oman maun mukaan. 

![image](https://user-images.githubusercontent.com/93308960/145271562-872ab483-725a-4ad4-b184-e60bc8c822b2.png)

# Lopputunnelmat

Projektia oli kiva tehdä vaikka pieniä mutkia tuli matkaan, se myös onnistui odotetusti. Sain hyvin tukea opettajamme sivuilta ja kurssilla tehdyistä tehtävistä. Sivun lopputulos oli tämän näköinen. 

![image](https://user-images.githubusercontent.com/93308960/145278134-49d4e039-bf34-4a97-a07f-bd4fffa875d5.png)


---

# Lähteet 

Journaldev, install wordpress on ubuntu 

https://www.journaldev.com/24954/install-wordpress-on-ubuntu

Ubuntu, install and configure WordPress

https://ubuntu.com/tutorials/install-and-configure-wordpress#1-overview

Community, How To Install WordPress on Ubuntu 20.04 with a LAMP Stack

https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-on-ubuntu-20-04-with-a-lamp-stack

Github

https://gist.github.com/hbokh/944987bb7f34dc38767830b882364e3e

Tero Karvinen

https://terokarvinen.com/
