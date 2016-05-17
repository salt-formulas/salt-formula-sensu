
{#
{%- if grains.os_family == 'Debian' %}

sensu_repo:
  pkgrepo.managed:
  - human_name: Sensu
  - name: deb http://repos.sensuapp.org/apt sensu main
  - file: /etc/apt/sources.list.d/sensu.list
  - key_url: salt://sensu/conf/sensu-apt.gpg

{%- elif grains.os_family == 'RedHat' %}

sensu_repo:
  pkgrepo.managed:
  - name: sensu
  - humanname: sensu-main
  - baseurl: http://repos.sensuapp.org/yum/el/$releasever/$basearch/
  - gpgcheck: 0

{%- endif %}
#}

/etc/sensu:
  file.directory:
  - user: sensu
  - group: sensu
  - mode: 755
  - makedirs: true

/etc/sensu/ssl:
  file.directory:
  - user: root
  - group: sensu
  - mode: 750
  - require:
    - file: /etc/sensu

/srv/sensu:
  file.directory:
  - user: root
  - group: root
  - mode: 755
  - makedirs: true
  - require:
    - file: /etc/sensu
