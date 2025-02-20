# frozen_string_literal: true
describe package('haproxy') do
  it { should be_installed }
end

describe directory '/etc/haproxy' do
  it { should exist }
end

cfg_content = [
  'global',
  '  user haproxy',
  '  group haproxy',
  '  log /dev/log syslog info',
  '  log-tag haproxy',
  '  chroot /var/lib/haproxy',
  '  quiet',
  '  stats socket /var/lib/haproxy/haproxy\.stat mode 600 level admin',
  '  stats timeout 2m',
  '  maxconn 4097',
  '  pidfile /var/run/haproxy\.pid',
  '',
  '',
  'defaults',
  '  timeout connect 5s',
  '  timeout client 50s',
  '  timeout server 50s',
  '  log global',
  '  mode http',
  '  balance roundrobin',
  '  option httplog',
  '  option dontlognull',
  '  option redispatch',
  '  option tcplog',
  '',
  '',
  'frontend http',
  '  default_backend rrhost',
  '  bind 0\.0\.0\.0:80',
  '  maxconn 2000',
  '  stats uri /haproxy\?stats',
  '  acl kml_request path_reg -i /kml/',
  '  acl bbox_request path_reg -i /bbox/',
  '  acl gina_host hdr\(host\) -i foo\.bar\.com',
  '  acl rrhost_host hdr\(host\) -i dave\.foo\.bar\.com foo\.foo\.com',
  '  acl source_is_abuser src_get_gpc0\(http\) gt 0',
  '  acl tile_host hdr\(host\) -i dough\.foo\.bar\.com',
  '  use_backend gina if gina_host',
  '  use_backend rrhost if rrhost_host',
  '  use_backend abuser if source_is_abuser',
  '  use_backend tiles_public if tile_host',
  '  option httplog',
  '  option dontlognull',
  '  option forwardfor',
  '  stick-table type ip size 200k expire 10m store gpc0',
  '  tcp-request connection track-sc1 src if !source_is_abuser',
  '',
  '',
  'backend tiles_public',
  '  server tile0 10\.0\.0\.10:80 check weight 1 maxconn 100',
  '  server tile1 10\.0\.0\.10:80 check weight 1 maxconn 100',
  '  acl conn_rate_abuse sc2_conn_rate gt 3000',
  '  acl data_rate_abuse sc2_bytes_out_rate gt 20000000',
  '  acl mark_as_abuser sc1_inc_gpc0 gt 0',
  '  option httplog',
  '  option dontlognull',
  '  option forwardfor',
  '  tcp-request content track-sc2 src',
  '  tcp-request content reject if conn_rate_abuse mark_as_abuser',
  '  stick-table type ip size 200k expire 2m store conn_rate\(60s\),bytes_out_rate\(60s\)',
  '  http-request set-header X-Public-User yes',
  '',
  'backend abuser',
  '  errorfile 403 /etc/haproxy/errors/403\.http',
  '',
  'backend rrhost',
  '  server tile0 10\.0\.0\.10:80 check weight 1 maxconn 100',
  '  server tile1 10\.0\.0\.10:80 check weight 1 maxconn 100',
  '',
  'backend gina',
  '  server tile0 10\.0\.0\.10:80 check weight 1 maxconn 100',
  '  server tile1 10\.0\.0\.10:80 check weight 1 maxconn 100',
]

describe file('/etc/haproxy/haproxy.cfg') do
  it { should exist }
  it { should be_owned_by 'haproxy' }
  it { should be_grouped_into 'haproxy' }
  its('content') { should match(/#{cfg_content.join('\n')}/) }
end

describe service('haproxy') do
  it { should be_running }
end
