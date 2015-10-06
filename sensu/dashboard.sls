{%- from "sensu/map.jinja" import dashboard with context %}
{%- if dashboard.enabled %}

include:
- sensu._common

sensu_dashboard_packages:
  pkg.installed:
  - names: {{ dashboard.pkgs }}
  - require_in:
    - file: /etc/sensu
    - service: service_sensu_dashboard

/etc/sensu/uchiwa.json:
  file.managed:
  - source: salt://sensu/files/uchiwa.json
  - template: jinja
  - mode: 644
  - require:
    - file: /etc/sensu
  - watch_in:
    - service: service_sensu_dashboard

service_sensu_dashboard:
  service.running:
  - name: uchiwa
  - enable: true

{%- endif %}