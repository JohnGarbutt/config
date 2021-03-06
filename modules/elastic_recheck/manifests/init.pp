# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Class to install and configure an instance of the elastic-recheck
# service.
#
class elastic_recheck (
  $gerrit_host,
  $gerrit_ssh_private_key,
  $gerrit_ssh_private_key_contents,
  #not used today, will be used when elastic-recheck supports it.
  $elasticsearch_url,
  $recheck_bot_passwd,
  $gerrit_user = 'elasticrecheck',
  $recheck_bot_nick = 'openstackrecheck'
) {
  group { 'recheck':
    ensure => 'present',
  }

  user { 'recheck':
    ensure  => present,
    home    => '/home/recheck',
    shell   => '/bin/bash',
    gid     => 'recheck',
    require => Group['recheck'],
  }

  vcsrepo { '/opt/elastic-recheck':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/elastic-recheck',
  }

  include pip
  exec { 'install_elastic-recheck' :
    command     => 'pip install /opt/elastic-recheck',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    notify      => Service['elastic-recheck'],
    subscribe   => Vcsrepo['/opt/elastic-recheck'],
    require     => Class['pip'],
  }

  file { '/var/run/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/var/log/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/etc/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/etc/elastic-recheck/elastic-recheck.conf':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    content => template('elastic_recheck/elastic-recheck.conf.erb'),
    require => File['/etc/elastic-recheck'],
  }

  file { '/etc/elastic-recheck/logging.config':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    source  => 'puppet:///modules/elastic_recheck/logging.config',
    require => File['/etc/elastic-recheck'],
  }

  file { '/etc/elastic-recheck/recheckwatchbot.yaml':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    source  => 'puppet:///modules/elastic_recheck/recheckwatchbot.yaml',
    require => File['/etc/elastic-recheck'],
  }

  # TODO(clarkb) put queries.yaml somewhere else.
  file { '/etc/elastic-recheck/queries.yaml':
    ensure  => link,
    target  => '/opt/elastic-recheck/queries.yaml',
    require => [
      Vcsrepo['/opt/elastic-recheck'],
      File['/etc/elastic-recheck'],
    ],
  }

  # Link in the queries directory for refactoring
  file { '/etc/elastic-recheck/queries':
    ensure  => link,
    target  => '/opt/elastic-recheck/queries',
    require => [
      Vcsrepo['/opt/elastic-recheck'],
      File['/etc/elastic-recheck'],
    ],
  }

  file { '/home/recheck':
    ensure  => directory,
    mode    => '0700',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/home/recheck/.ssh':
    ensure  => directory,
    mode    => '0700',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { $gerrit_ssh_private_key:
    ensure  => present,
    mode    => '0600',
    owner   => 'recheck',
    group   => 'recheck',
    content => $gerrit_ssh_private_key_contents,
    require => User['recheck'],
  }

  file { '/etc/init.d/elastic-recheck':
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/elastic_recheck/elastic-recheck.init',
  }

  service { 'elastic-recheck':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/elastic-recheck/elastic-recheck.conf'],
    require   => [
      File['/etc/init.d/elastic-recheck'],
      File['/etc/elastic-recheck/elastic-recheck.conf'],
      File['/etc/elastic-recheck/queries.yaml'],
      Exec['install_elastic-recheck'],
    ],
  }
}
