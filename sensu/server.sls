{%- from "sensu/map.jinja" import server with context %}
{%- if server.enabled %}

include:
- sensu._common

sensu_server_packages:
  pkg.installed:
  - names: {{ server.pkgs }}
  - require_in:
    - file: /etc/sensu

sensu_server_pip:
  pip.installed:
  - name: sensu
  - require:
    - pkg: sensu_server_packages

purge_sensu_conf_dir:
  file.directory:
    - name: /etc/sensu/conf.d/
    - clean: True

{%- if server.mine_checks %}

{%- set client_checks = {} %}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}

{%- set rowloop = loop %}

{%- if node_grains.get('sensu', {}) is not none %}

{%- for check_name, check in node_grains.get('sensu', {}).get('checks', {}).iteritems() %}

/etc/sensu/conf.d/check_{{ check_name }}.json_{{ rowloop.index }}-{{ loop.index }}:
  file.managed:
  - name: /etc/sensu/conf.d/check_{{ check_name }}.json
  - source: salt://sensu/files/check.json
  - template: jinja
  - defaults:
    check_name: "{{ check_name }}"
    check: {{ check|yaml }}
  - require:
    - pkg: sensu_server_packages
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

{%- endfor %}

{%- endif %}

{%- endfor %}

{%- endif %}

{%- for check in server.get('checks', []) %}

/etc/sensu/conf.d/check_{{ check.name }}.json:
  file.managed:
  - source: salt://sensu/files/check_manual.json
  - template: jinja
  - defaults:
    check_name: "{{ check.name }}"
  - require:
    - pkg: sensu_server_packages
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

{%- endfor %}

{%- for mutator in server.get('mutators', []) %}

/etc/sensu/conf.d/mutator_{{ mutator.name }}.json:
  file.managed:
  - source: salt://sensu/files/mutator.json
  - template: jinja
  - defaults:
    mutator_name: "{{ mutator.name }}"
  - require:
    - file: /etc/sensu/config.json
    - pkg: sensu_packages
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

{%- endfor %}

{%- for handler_name, handler in server.get('handler', {}).iteritems() %}

{%- if handler_name in ['default', 'flapjack', 'mail', 'sccd', 'stdout', 'statsd', 'slack']  %}

{%- include "sensu/server/_handler_"+handler_name+".sls" %}

{%- endif %}

{%- endfor %}

/etc/sensu/conf.d/api.json:
  file.managed:
  - source: salt://sensu/files/api.json
  - template: jinja
  - mode: 644
  - require:
    - file: /etc/sensu
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

/etc/sensu/conf.d/redis.json:
  file.managed:
  - source: salt://sensu/files/redis.json
  - template: jinja
  - mode: 644
  - require:
    - file: /etc/sensu
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

service_sensu_server:
  service.running:
  - name: sensu-server
  - enable: true

service_sensu_api:
  service.running:
  - name: sensu-api
  - enable: true

/srv/sensu/handlers:
  file.recurse:
  - clean: true
  - source: salt://sensu/files/plugins/handlers
  - user: sensu
  - group: sensu
  - file_mode: 755
  - dir_mode: 755
  - makedirs: true
  - require:
    - file: /srv/sensu

/srv/sensu/mutators:
  file.recurse:
  - clean: true
  - source: salt://sensu/files/plugins/mutators
  - user: sensu
  - group: sensu
  - file_mode: 755
  - dir_mode: 755
  - makedirs: true
  - require:
    - file: /srv/sensu

{%- endif %}