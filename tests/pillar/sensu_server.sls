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
        - pagerduty
      stdout:
        enabled: true
      pipe:
        enabled: true
        command: "/usr/bin/tee /tmp/debug"
      mail:
        mail_to: 'mail@domain.cz'
        host: smtp1.domain.cz
        port: 465
        user: 'mail@domain.cz'
        password: 'pwd'
        authentication: cram_md5
        encryption: ssl
        domain: 'domain.cz'
      pagerduty:
        api_key: 'insert-your-key-here'
      slack:
        webhook_url: 'http://insert-url'
        filter: test_filter
      sfdc:
        sfdc_client_id: 'client_id'
        sfdc_client_secret: 'secret'
        sfdc_username: 'username'
        sfdc_password: 'password'
        sfdc_auth_url: 'url'
        environment: 'env'
        sfdc_organization_id: 'org'
        token_cache_file: "/var/run/sensu/token_cache_file"
        filter: test_filter
    filter:
      test_filter:
        negate: false
        attributes:
          occurrences: "eval: value == 3 || value % 20 == 0 || ':::action:::' == 'resolve'"

  client:
    enabled: false

