
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

Sensu Client with check explicitly disabled

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
        check:
          local_linux_storage_swap_usage:
            enabled: False

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

Sensu SalesForce handler

.. code-block:: yaml

    sensu:
      server:
        enabled: true
        handler:
          default:
            enabled: true
            set:
            - sfdc
          stdout:
            enabled: true
          sfdc:
            enabled: true
            sfdc_client_id: "3MVG9Oe7T3Ol0ea4MKj"
            sfdc_client_secret: 11482216293059
            sfdc_username: test@test1.test
            sfdc_password: passTemp
            sfdc_auth_url: https://mysite--scloudqa.cs12.my.salesforce.com
            environment: a2XV0000001
            sfdc_organization_id: 00DV00000

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

Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-sensu/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-sensu

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
