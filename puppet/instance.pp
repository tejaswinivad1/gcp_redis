define redis::instance($service_name = $title, $port, $appendonly = false, $maxmemory = 0, $maxmemory_policy = "volatile-lru", $auto_aof_rewrite_percentage = 100, $auto_aof_rewrite_min_size = "64mb", $slave_output_buffer_limit = "1024m") {
  include redis::prereqs

  file { "/mnt/redis/${service_name}":
    ensure => directory,
    mode => 750,
    owner => redis,
    group => redis,
    require => [User[redis], File["/mnt/redis"]]
  }

  file { "/var/lib/${service_name}":
    ensure => link,
    target => "/mnt/redis/${service_name}"
  }

  file { "/etc/${service_name}.conf":
    content => template("redis/redis.conf"),
    mode => 644,
  }

  file { "/etc/init.d/${service_name}":
    content => template("redis/redis.init"),
    mode => 755,
    require => [Package[redis], File["/var/lib/${service_name}"], File["/etc/${service_name}.conf"]]
  }

  file { "/var/log/redis/${service_name}.log":
    ensure => present,
    owner => redis,
    group => redis,
    mode => 644,
    require => [File["/var/log/redis"], User[redis]]
  }

  service { "${service_name}":
    enable => true,
    ensure => true,
    start => "/etc/init.d/${service_name} start",
    hasrestart => true,
    hasstatus => true,
    require => [Package[redis], User[redis], File["/mnt/redis/${service_name}"],
                File["/etc/init.d/${service_name}"], File["/var/log/redis/${service_name}.log"]]
  }

  # don't let Puppet restart the service in production
  if $realm == "prod" {
    Service["${service_name}"] {
      restart => "/bin/true",
    }
  }
}