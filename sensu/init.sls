
{%- if pillar.sensu is defined %}
include:
{%- if pillar.sensu.server is defined %}
- sensu.server
{%- endif %}
{%- if pillar.sensu.client is defined %}
- sensu.client
{%- endif %}
{%- if pillar.sensu.dashboard is defined %}
- sensu.dashboard
{%- endif %}
{%- endif %}
