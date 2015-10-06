
/etc/sensu/conf.d/flapjack.json:
  file.managed:
  - source: salt://sensu/files/handlers/{{ handler_name }}.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api

/etc/sensu/extensions/handlers/flapjack.rb:
  file.managed:
  - source: salt://sensu/files/plugins/handlers/flapjack.rb
  - mode: 660
  - user: sensu
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
