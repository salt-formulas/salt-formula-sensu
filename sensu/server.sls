{%- from "sensu/map.jinja" import server with context %}
{%- if server.enabled %}

include:
- sensu._common
- sensu.client

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

{%- if server.mine_checks %}

{%- for node_name, node_grains in salt['mine.get']('*', 'grains.items').iteritems() %}

{%- set rowloop = loop %}

{%- for check_name, check in node_grains.get('sensu', {}).get('check', {}).iteritems() %}

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
  - require_in:
    - file: sensu_conf_dir_clean
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

{%- endfor %}

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
  - require_in:
    - file: sensu_conf_dir_clean
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
    - pkg: sensu_server_packages
  - require_in:
    - file: sensu_conf_dir_clean
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

{%- endfor %}

{%- for filter_name, filter in server.get('filter', {}).iteritems() %}

/etc/sensu/conf.d/filter_{{ filter_name }}.json:
  file.managed:
  - source: salt://sensu/files/filter.json
  - template: jinja
  - defaults:
    filter_name: "{{ filter_name }}"
  - require:
    - pkg: sensu_server_packages
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

{%- endfor %}

{%- for handler_name, handler in server.get('handler', {}).iteritems() %}

{%- if handler.get('enabled', True) and handler_name in ['default', 'flapjack', 'mail', 'sccd', 'stdout', 'statsd', 'slack', 'pipe', 'sfdc', 'pagerduty', 'hipchat'] %}

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
  - require_in:
    - file: sensu_conf_dir_clean
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
  - require_in:
    - file: sensu_conf_dir_clean
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

sensu_conf_dir_clean:
  file.directory:
    - name: /etc/sensu/conf.d/
#    - clean: True
    - require:
      - file: /etc/sensu/conf.d/client.json
      - file: /etc/sensu/conf.d/rabbitmq.json

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
