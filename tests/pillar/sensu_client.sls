sensu:
  client:
    enabled: true
    plugin:
      monitoring_for_openstack:
        enabled: true
    message_queue:
      engine: rabbitmq
      host: rabbitmq
      port: 5672
      user: monitor
      password: pwd
      virtual_host: '/monitor'

