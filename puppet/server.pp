class redis::server {
  include redis::prereqs

  redis::instance { "redis-${redis_port}":
    port => "${redis_port}",
    appendonly => true
  }

  # run a backup every 4 hours
  cron { "backup-redis-${redis_port}":
    ensure => present,
    command => "cronic backup-redis ${redis_port}",
    user => root,
    hour => [1, 5, 9, 13, 17, 21],
    minute => random("backup-redis-${redis_port} minute", 0, 59)
  }
}

class redis::server::sysctl inherits centos::sysctl {
  Sysctl_entry["vm.overcommit_memory"] {
    value => 1
  }
}

class redis::server::logstash {
  include redis::prereqs

  redis::instance { redis-6399:
    port => 6399,
    maxmemory => floor($memorysize_mb * 0.3 * 1048576),
    maxmemory_policy => "noeviction"
  }
}

class redis::server::lookout {
  include redis::prereqs

  redis::instance { redis-6400:
    port => 6400,
    appendonly => true,
    maxmemory => floor($memorysize_mb * 0.3 * 1048576),
    maxmemory_policy => "noeviction"
  }
}

class redis::server::proxy {
  include redis::prereqs

  redis::instance { "redis-proxy":
    port => 6379,
    appendonly => false,
    maxmemory => floor(($memorysize_mb - 600) * 1048576)
  }
}

define redis::server::redis_calculon($service_name="${title}", $port) {
  include redis::prereqs

  redis::instance { "redis-${port}":
    port => "${port}",
    appendonly => false,
    slave_output_buffer_limit => "4096m",
    auto_aof_rewrite_percentage => "100"
  }

  # run a backup every 4 hours
  cron { "backup-redis-${port}":
    ensure => present,
    command => "cronic backup-redis ${port}",
    user => root,
    hour => [3, 7, 11, 15, 19, 23],
    minute => random("backup-redis-${port} minute", 0, 59)
  }

  # run a cleanup script every 4 hours
  cron { "prune-active-items-${port}":
    ensure => present,
    command => "cronic prune-active-items.sh ${port}",
    user => root,
    hour => [1, 5, 9, 13, 17, 21],
    minute => random("prune-active-items-${port} minute", 0, 59)
  }
}

define redis::server::radar_results($service_name="${title}", $port, $enabled) {
  include redis::prereqs

  redis::instance { "redis-${port}":
    port => "${port}",
    appendonly => false,
    slave_output_buffer_limit => "4096m",
    auto_aof_rewrite_percentage => "100"
  }

  # run a backup every 4 hours
  cron { "backup-redis-${port}":
    ensure => present,
    command => "cronic backup-redis ${port}",
    user => root,
    hour => [3, 7, 11, 15, 19, 23],
    minute => random("backup-redis-${port} minute", 0, 59)
  }

  redis::utils::scan_keys { "scan-redis-${port}":
    port => $port,
    enabled => $enabled
  }
}

define redis::server::mulcher($enabled) {
  include redis::prereqs

  redis::instance { redis-6383:
    port => 6383,
    appendonly => false,
    slave_output_buffer_limit => "4096m",
    auto_aof_rewrite_percentage => "100"
  }

  # run a backup every 4 hours
  cron { backup-redis-6383:
    ensure => present,
    command => "cronic backup-redis 6383",
    user => root,
    hour => [0, 4, 8, 12, 16, 20],
    minute => random("backup-redis-6383 minute", 0, 59)
  }

  redis::utils::scan_keys { "scan-redis-6383":
    port => 6383,
    db => 5,
    enabled => $enabled
  }
}

define redis::server::redis_vault($service_name="${title}", $port, $enabled) {
  include redis::prereqs

  redis::instance { "redis-${port}":
    port => "${port}",
    appendonly => false,
    slave_output_buffer_limit => "4096m"
  }

  # run a backup every 4 hours
  cron { "backup-redis-${port}":
    ensure => present,
    command => "cronic backup-redis ${port}",
    user => root,
    hour => [$port % 4, 4 + $port % 4, 8 + $port % 4,
             12 + $port % 4, 16 + $port % 4, 20 + $port % 4],
    minute => random("backup-redis-${port} minute", 0, 59)
  }

  redis::utils::scan_keys { "scan-vault-${port}":
    port => $port,
    enabled => $enabled
  }
}

define redis::server::redis_queue($service_name="${title}", $port) {
  include redis::prereqs

  redis::instance { "redis-${port}":
    port => "${port}",
    appendonly => false,
    slave_output_buffer_limit => "4096m",
    auto_aof_rewrite_percentage => "200",
    auto_aof_rewrite_min_size => "1gb"
  }
}
