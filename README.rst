
=====
Sensu
=====

Sample pillars
==============

Sensu Server with API

.. code-block:: yaml

    sensu:
      server:
        enabled: true
        keepalive_warning: 20
        keepalive_critical: 60
        mine_checks: true
        database:
          engine: redis
          host: localhost
          port: 6379
        message_queue:
          engine: rabbitmq
          host: rabbitmq
          port: 5672
          user: monitor
          password: pwd
          virtual_host: '/monitor'
        bind:
          address: 0.0.0.0
          port: 4567
        handler:
          default:
            enabled: true
            set:
            - mail
            - pipe
          stdout:
            enabled: true
          mail:
            mail_to: 'mail@domain.cz'
            host: smtp1.domain.cz
            port: 465
            user: 'mail@domain.cz'
            password: 'pwd'
            authentication: cram_md5
            encryption: ssl
            domain: 'domain.cz'
          pipe:
            enabled: true
            command: /usr/bin/tee /tmp/debug

Sensu Dashboard (now uchiwa)

.. code-block:: yaml

    sensu:
      dashboard:
        enabled: true
        bind:
          address: 0.0.0.0
          port: 8080
        admin:
          username: admin
          password: pass

Sensu Client

.. code-block:: yaml

    sensu:
      client:
        enabled: true
        message_queue:
          engine: rabbitmq
          host: rabbitmq
          port: 5672
          user: monitor
          password: pwd
          virtual_host: '/monitor'

Sensu Client with community plugins

.. code-block:: yaml

    sensu:
      client:
        enabled: true
        plugin:
          sensu_community_plugins:
            enabled: true
          monitoring_for_openstack:
            enabled: true
          ruby_gems:
            enabled: True
            name:
              bunny:
        message_queue:
          engine: rabbitmq
          host: rabbitmq
          port: 5672
          user: monitor
          password: pwd
          virtual_host: '/monitor'

Read more
=========

* http://docs.sensuapp.org/0.9/installing_sensu.html
* https://speakerdeck.com/joemiller/practical-examples-with-sensu-monitoring-framework
* https://github.com/fridim/nagios-plugin-check_galera_cluster
* http://www.reimann.sh/2011/06/30/nagios-check-pacemaker-failed-actions/
* http://sys4.de/en/blog/2014/01/23/montoring-pacemaker-nagios/
* https://raw.githubusercontent.com/sensu/sensu-community-plugins/master/plugins/openstack/neutron/neutron-agent-status.py
* https://github.com/sensu/sensu-community-plugins/blob/master/plugins/openstack/keystone/check_keystone-api.sh
* http://openstack.prov12n.com/monitoring-openstack-nagios-3/
* https://raw.githubusercontent.com/drewkerrigan/nagios-http-json/master/check_http_json.py
* https://github.com/opinkerfi/nagios-plugins/tree/master/check_ibm_bladecenter
* https://github.com/opinkerfi/nagios-plugins/tree/master/check_storwize
* https://github.com/ehazlett/sensu-py/
* https://github.com/Level-Up/Supervisord-Nagios-Plugin/blob/master/check_supv.py
