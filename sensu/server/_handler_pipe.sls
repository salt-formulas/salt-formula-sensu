
/etc/sensu/conf.d/handler_pipe.json:
  file.managed:
  - source: salt://sensu/files/handlers/pipe.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "handler"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
