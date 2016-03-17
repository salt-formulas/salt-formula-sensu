
/etc/sensu/conf.d/mail.json:
  file.managed:
  - source: salt://sensu/files/handlers/mail.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "config"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/conf.d/handler_mail.json:
  file.managed:
  - source: salt://sensu/files/handlers/mail.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "handler"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/handlers/mail.py:
  file.managed:
  - source: salt://sensu/files/plugins/handlers/notification/mail.py
  - mode: 700
  - user: sensu
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api