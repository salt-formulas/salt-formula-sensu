
/etc/sensu/conf.d/sfdc.json:
  file.managed:
  - source: salt://sensu/files/handlers/sfdc.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "config"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/conf.d/handler_sfdc.json:
  file.managed:
  - source: salt://sensu/files/handlers/sfdc.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "handler"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/handlers/sfdc.py:
  file.managed:
  - source: salt://sensu/files/plugins/handlers/notification/sfdc.py
  - mode: 755
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

/etc/sensu/handlers/salesforce.py:
  file.managed:
  - source: salt://sensu/files/plugins/handlers/notification/salesforce.py
  - mode: 644
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
