
gem_sensu_pagerduty:
  gem.installed:
  - name: pagerduty
  - gem_bin: /opt/sensu/embedded/bin/gem

/etc/sensu/conf.d/pagerduty.json:
  file.managed:
  - source: salt://sensu/files/handlers/pagerduty.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "config"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/conf.d/handler_pagerduty.json:
  file.managed:
  - source: salt://sensu/files/handlers/pagerduty.json
  - template: jinja
  - defaults:
    handler_name: "{{ handler_name }}"
    handler_setting: "handler"
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require_in:
    - file: sensu_conf_dir_clean

/etc/sensu/handlers/pagerduty.rb:
  file.managed:
  - source: salt://sensu/files/plugins/handlers/notification/pagerduty.rb
  - mode: 750
  - user: root
  - group: sensu
  - watch_in:
    - service: service_sensu_server
    - service: service_sensu_api
  - require:
    - gem: gem_sensu_pagerduty
