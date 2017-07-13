
/etc/sensu/conf.d/sccd.json:
  file.managed:
  - source: salt://sensu/files/handlers/sccd.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "config"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/conf.d/handler_sccd.json:
  file.managed:
  - source: salt://sensu/files/handlers/sccd.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "handler"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/handlers/sccd.py:
  file.managed:
  - source: salt://sensu/files/plugins/handlers/notification/sccd.py
  - makedirs: True
  - mode: 700
  - user: sensu
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api