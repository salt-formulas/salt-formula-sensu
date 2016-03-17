
python-statsd:
  pip.installed:
    - name: python-statsd == 1.6.0

/etc/sensu/conf.d/statsd.json:
  file.managed:
  - source: salt://sensu/files/handlers/statsd.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "config"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require:
    - pip: python-statsd
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/conf.d/handler_statsd.json:
  file.managed:
  - source: salt://sensu/files/handlers/statsd.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "handler"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/handlers/statsd_handler.py:
  file.managed:
  - source: salt://sensu/files/plugins/handlers/notification/statsd.py
  - mode: 700
  - user: sensu
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api