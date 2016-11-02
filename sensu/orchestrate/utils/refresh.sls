salt_sensu_client:
  salt.state:
    - tgt: 'G@roles:sensu.client'
    - tgt_type: compound
    - sls: sensu.client

salt_clear_grains:
  salt.runner:
    - name: cache.clear_grains
    - tgt: 'G@roles:sensu.client'
    - require:
      - salt: salt_sensu_client

salt_sensu_client_salt_grains:
  salt.state:
    - tgt: 'G@roles:sensu.client'
    - tgt_type: compound
    - sls: salt.minion.grains
    - require:
      - salt: salt_clear_grains

salt_mine_flush:
  salt.function:
    - name: mine.flush
    - tgt_type: compound
    - tgt: 'G@roles:sensu.client'
    - require:
      - salt: salt_sensu_client_salt_grains

salt_mine_update:
  salt.function:
    - name: mine.update
    - tgt: 'G@roles:sensu.client'
    - tgt_type: compound
    - require:
      - salt: salt_mine_flush

salt_sensu_server:
  salt.state:
    - tgt: 'G@roles:sensu.server'
    - tgt_type: compound
    - sls: sensu.server
    - require:
      - salt: salt_mine_update
