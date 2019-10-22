define redis::utils::scan_keys($port, $db = "0", $enabled = true) {
  if $enabled {
    # Cron job to scan through all the keys in a redis database
    # so that they get evicted in a timely manner
    cron { "scan-keys-${port}":
      command => "cronic scan-keys --port ${port} --db ${db}",
      user => "runscope",
      hour => [0,6,12,18],
      minute => random("scan-keys-${port}", 0, 59)
    }
  }
  else {
    cron { "scan-keys-${port}":
      user => "runscope",
      ensure => absent
    }
  }
}