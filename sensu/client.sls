{%- from "sensu/map.jinja" import client with context %}
{%- if client.enabled %}

include:
- sensu._common

sensu_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}
  - require_in:
    - file: /etc/sensu

/etc/sensu/plugins:
  file.recurse:
  - clean: true
  - source: salt://sensu/files/checks
  - user: sensu
  - group: sensu
  - file_mode: 755
  - dir_mode: 755
  - makedirs: true
  - require:
    - file: /srv/sensu

{%- for plugin_name, plugin in client.plugin.iteritems() %}
{%- if plugin.enabled %}

{%- if plugin_name == 'sensu_community_plugins' %}

sensu_client_community_plugins
  gem.installed:
  - names:
    - sensu-plugin

{%- endif %}

{%- if plugin_name == 'monitoring_for_openstack' %}

sensu_monitor_openstack_six:
  pip.installed:
  - name: six>=1.9.0

sensu_monitor_openstack_source:
  git.latest:
  - name: https://github.com/stackforge/monitoring-for-openstack.git
  - target: /root/monitoring-for-openstack
  - rev: master
  - require:
    - pip: sensu_monitor_openstack_six

sensu_monitor_openstack_install:
  cmd.run:
  - name: python setup.py install
  - cwd: /root/monitoring-for-openstack
  - unless: pip freeze | grep monitoring-for-openstack
  - require:
    - git: sensu_monitor_openstack_source

{%- endif %}

{%- endif %}
{%- endfor %}

sensu_client_check_grains:
  file.managed:
  - name: /etc/salt/grains
  - source: salt://sensu/files/checks.grain
  - template: jinja
  - mode: 600
  - require:
    - pkg: sensu_client_packages

/etc/sensu/conf.d/rabbitmq.json:
  file.managed:
  - source: salt://sensu/files/rabbitmq.json
  - template: jinja
  - mode: 644
  - require:
    - file: /etc/sensu
  - watch_in:
    - service: service_sensu_client

/etc/sensu/conf.d/client.json:
  file.managed:
  - source: salt://sensu/files/client.json
  - template: jinja
  - mode: 644
  - require:
    - file: /etc/sensu
  - watch_in:
    - service: service_sensu_client

service_sensu_client:
  service.running:
  - name: sensu-client
  - enable: true
  - require:
    - pkg: sensu_client_packages

/etc/sudoers.d/90-sensu-user:
  file.managed:
  - source: salt://sensu/files/sudoer
  - user: root
  - group: root
  - mode: 440

{%- endif %}
