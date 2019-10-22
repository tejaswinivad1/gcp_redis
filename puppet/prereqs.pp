class redis::prereqs {
  package { jemalloc:
    ensure => present
  }

  exec { download-redis-rpm:
    command => "curl -sO https://s3.amazonaws.com/runscope-packages/redis-3.2.10-2.el7.x86_64.rpm",
    cwd => "/var/lib/puppet/package_cache",
    creates => "/var/lib/puppet/package_cache/redis-3.2.10-2.el7.x86_64.rpm"
  }

  package { redis:
    ensure => latest,
    source => "/var/lib/puppet/package_cache/redis-3.2.10-2.el7.x86_64.rpm",
    provider => rpm,
    require => [Exec[download-redis-rpm], Package[jemalloc]]
  }

  # We will replace the Redis service definition with our own, below
  service { redis:
    ensure => false,
    enable => false,
    require => Package[redis]
  }

  exec { "install-rdbtools":
    #command => "/usr/bin/pip install rdbtools",
    #unless => "/usr/bin/pip freeze | grep -q ^rdbtools",
    command => "/usr/local/python2.7.11/bin/pip install rdbtools",
    unless => "/usr/local/python2.7.11/bin/pip freeze | grep -q ^rdbtools",
    require => Package[redis]
  }

  user { redis:
    provider => useradd,
    ensure => present,
    home => "/mnt/redis",
    comment => "Redis",
    password => "!!",
    shell => "/sbin/nologin",
    require => Package[redis]
  }

  file { "/mnt/redis":
    ensure => directory,
    owner => redis,
    group => redis,
    mode => 755,
    require => [Package[redis], User[redis]]
  }

  file { "/etc/logrotate.d/redis":
    source => "puppet:///modules/redis/redis.logrotate",
    mode => 644,
    require => Package[redis]
  }

  file { "/var/log/redis":
    ensure => directory,
    owner => redis,
    group => redis,
    mode => 755,
    require => User[redis]
  }
}