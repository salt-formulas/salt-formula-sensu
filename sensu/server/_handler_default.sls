
/etc/sensu/conf.d/handler_{{ handler_name }}.json:
  file.managed:
  - source: salt://sensu/files/handlers/{{ handler_name }}.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
