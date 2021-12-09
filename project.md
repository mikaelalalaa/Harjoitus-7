## Alku

Käytössä on kaksi virtuaali konetta Ubuntu 20.4 LTS käyttöjärjestelmällä. Nähin olin luonut master ja minion yhteyden ja testannut sitä.

## SSH asennus
   
Jotta saisin putty ohjelmaa yhteyden asensin ensimmäisenä `openssh-server`. Tein hakemistoon srv/salt/sshd `init.sls` tiedoston ja ajoin komennolla 


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
