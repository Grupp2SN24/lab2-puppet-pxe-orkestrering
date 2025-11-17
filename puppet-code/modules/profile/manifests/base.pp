# Base profile for all Linux servers
class profile::base {
  
  # Ensure basic packages
  package { ['vim', 'htop', 'curl', 'wget', 'sudo']:
    ensure => present,
  }
  
  # Set timezone
  file { '/etc/timezone':
    ensure  => file,
    content => "Europe/Stockholm\n",
  }
  
  # Create a banner file
  file { '/etc/motd':
    ensure  => file,
    content => "Welcome to Debian managed by Puppet\nHostname: ${facts['networking']['fqdn']}\n",
  }
}
