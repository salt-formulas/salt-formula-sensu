{%- from "sensu/map.jinja" import client with context %}
{%- if client.enabled %}

include:
- sensu._common

sensu_client_packages:
  pkg.installed:
  - names: {{ client.pkgs }}
  - require_in:
    - file: /etc/sensu

/etc/sensu/plugins:
  file.recurse:
  - clean: true
  - source: salt://sensu/files/checks
  - user: sensu
  - group: sensu
  - file_mode: 755
  - dir_mode: 755
  - makedirs: true
  - require:
    - file: /srv/sensu

{%- for plugin_name, plugin in client.plugin.iteritems() %}
{%- if plugin.enabled %}

{%- if plugin_name == 'ruby_gems' %}
{%- for gem_name, gem in client.plugin.ruby_gems.name.iteritems() %}

sensu_client_gem_{{ gem_name }}_install:
  gem.installed:
  - gem_bin: /opt/sensu/embedded/bin/gem
  - name: {{ gem_name }}

{% endfor %}
{%- endif %}

{%- if plugin_name == 'sensu_community_plugins' %}

sensu_client_community_plugins:
  pkg.installed:
  - names: ruby-sensu-plugin

{%- endif %}

{%- if plugin_name == 'monitoring_for_openstack' %}

sensu_monitoring_os_packages:
  pkg.installed:
  - name: monitoring-for-openstack

{%- endif %}

{%- if plugin_name == 'network_monitoring' %}

sensu_monitoring_network_packages:
  pkg.installed:
  - name: libnet-snmp-perl

{%- endif %}

{%- endif %}
{%- endfor %}

sensu_client_checks_grains_dir:
  file.directory:
  - name: /etc/salt/grains.d
  - mode: 700
  - makedirs: true
  - user: root

{%- set service_grains = {'sensu': {'check': {}}} %}
{%- for service_name, service in pillar.items() %}
{%- if service.get('_support', {}).get('sensu', {}).get('enabled', False) %}
{%- set grains_fragment_file = service_name+'/meta/sensu.yml' %}
{%- macro load_grains_file() %}{% include grains_fragment_file %}{% endmacro %}
{%- set grains_yaml = load_grains_file()|load_yaml %}
{%- for check_name, check in client.get('check', {}).items() %}
  {%- if check_name in grains_yaml.check and not check.get('enabled', True) %}
    {%- do grains_yaml.check.pop(check_name) %}
  {%- endif %}
{%- endfor %}
{%- do service_grains.sensu.check.update(grains_yaml.check) %}
{%- endif %}
{%- endfor %}

sensu_client_checks_grains:
  file.managed:
  - name: /etc/salt/grains.d/sensu
  - source: salt://sensu/files/sensu.grain
  - template: jinja
  - mode: 600
  - defaults:
    service_grains: {{ service_grains|yaml }}
  - require:
    - pkg: sensu_client_packages
    - file: sensu_client_checks_grains_dir

/etc/sensu/conf.d/rabbitmq.json:
  file.managed:
  - source: salt://sensu/files/rabbitmq.json
  - template: jinja
  - mode: 644
  - require:
    - file: /etc/sensu
  - watch_in:
    - service: service_sensu_client

/etc/sensu/conf.d/client.json:
  file.managed:
  - source: salt://sensu/files/client.json
  - template: jinja
  - mode: 644
  - require:
    - file: /etc/sensu
  - watch_in:
    - service: service_sensu_client

service_sensu_client:
  service.running:
  - name: sensu-client
  - enable: true
  - require:
    - pkg: sensu_client_packages

/etc/sudoers.d/90-sensu-user:
  file.managed:
  - source: salt://sensu/files/sudoer
  - user: root
  - group: root
  - mode: 440

{%- endif %}
