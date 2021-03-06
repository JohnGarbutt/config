class openstack_project::eavesdrop (
  $nickpass = '',
  $sysadmins = [],
  $statusbot_nick = '',
  $statusbot_password = '',
  $statusbot_server = '',
  $statusbot_channels = '',
  $statusbot_auth_nicks = '',
  $statusbot_wiki_user = '',
  $statusbot_wiki_password = '',
  $statusbot_wiki_url = '',
  $statusbot_wiki_pageid = '',
) {
  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80],
    sysadmins                 => $sysadmins
  }
  include meetbot

  meetbot::site { 'openstack':
    nick      => 'openstack',
    nickpass  => $nickpass,
    network   => 'FreeNode',
    server    => 'chat.freenode.net:7000',
    channels  => [
        '#openstack',
        '#openstack-ceilometer',
        '#openstack-climate',
        '#openstack-dev',
        '#openstack-dns',
        '#openstack-infra',
        '#openstack-ironic',
        '#openstack-marconi',
        '#openstack-meeting',
        '#openstack-meeting-alt',
        '#openstack-neutron',
        '#openstack-qa',
        '#openstack-trove',
        '#savanna',
        '#storyboard',
        '#tripleo',
    ],
    use_ssl   => 'True'
  }

  class { 'statusbot':
    nick          => $statusbot_nick,
    password      => $statusbot_password,
    server        => $statusbot_server,
    channels      => $statusbot_channels,
    auth_nicks    => $statusbot_auth_nicks,
    wiki_user     => $statusbot_wiki_user,
    wiki_password => $statusbot_wiki_password,
    wiki_url      => $statusbot_wiki_url,
    wiki_pageid   => $statusbot_wiki_pageid,
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
