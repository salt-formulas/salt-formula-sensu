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

