
/etc/sensu/conf.d/handler_stdout.json:
  file.managed:
  - source: salt://sensu/files/handlers/stdout.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "handler"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: purge_sensu_conf_dir
