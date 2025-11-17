# Profile for PXE installation server
class profile::pxe_install {
  
  # Install required packages
  package { ['isc-dhcp-server', 'tftpd-hpa', 'apache2', 'syslinux-common', 'pxelinux', 'wget']:
    ensure => present,
  }
  
  # TFTP Configuration
  file { '/etc/default/tftpd-hpa':
    ensure  => file,
    content => "TFTP_USERNAME=\"tftp\"\nTFTP_DIRECTORY=\"/var/lib/tftpboot\"\nTFTP_ADDRESS=\"0.0.0.0:69\"\nTFTP_OPTIONS=\"--secure\"\n",
    require => Package['tftpd-hpa'],
  }
  
  # Create TFTP directory structure
  file { '/var/lib/tftpboot':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['tftpd-hpa'],
  }
  
  file { '/var/lib/tftpboot/pxelinux.cfg':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/var/lib/tftpboot'],
  }
  
  file { '/var/lib/tftpboot/debian':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/var/lib/tftpboot'],
  }
  
  # Copy syslinux files
  exec { 'copy_syslinux_files':
    command => '/bin/bash -c "/bin/cp /usr/lib/syslinux/modules/bios/*.c32 /var/lib/tftpboot/ && /bin/cp /usr/lib/PXELINUX/pxelinux.0 /var/lib/tftpboot/"',
    creates => '/var/lib/tftpboot/pxelinux.0',
    require => [Package['syslinux-common', 'pxelinux'], File['/var/lib/tftpboot']],
  }
  
  # Download and extract Debian Bookworm netboot
  exec { 'download_debian_netboot':
    command => '/bin/bash -c "cd /tmp && /usr/bin/wget -q -O netboot.tar.gz http://ftp.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/netboot.tar.gz && /bin/tar -xzf netboot.tar.gz && /bin/cp -r debian-installer/amd64/linux debian-installer/amd64/initrd.gz /var/lib/tftpboot/debian/ && /bin/rm -rf netboot.tar.gz debian-installer"',
    creates => '/var/lib/tftpboot/debian/linux',
    require => [Package['wget'], File['/var/lib/tftpboot/debian']],
    timeout => 600,
  }
  
  # Create PXE menu
  file { '/var/lib/tftpboot/pxelinux.cfg/default':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("END")
      DEFAULT vesamenu.c32
      PROMPT 0
      TIMEOUT 100
      ONTIMEOUT debian
      
      MENU TITLE PXE Boot Menu - Lab Environment
      
      LABEL debian
        MENU LABEL Install Debian Bookworm (Automated)
        KERNEL debian/linux
        APPEND initrd=debian/initrd.gz auto=true priority=critical url=http://192.0.2.10/preseed/bookworm.cfg debian-installer/locale=sv_SE keyboard-configuration/xkb-keymap=se netcfg/get_hostname=debian-auto netcfg/get_domain=lab.example.local
      
      LABEL local
        MENU LABEL Boot from local disk
        LOCALBOOT 0
      | END
    ,
    require => [File['/var/lib/tftpboot/pxelinux.cfg'], Exec['download_debian_netboot']],
  }
  
  # Start TFTP service
  service { 'tftpd-hpa':
    ensure  => running,
    enable  => true,
    require => [File['/etc/default/tftpd-hpa'], File['/var/lib/tftpboot']],
  }
  
  # DHCP Configuration
  file { '/etc/dhcp/dhcpd.conf':
    ensure  => file,
    content => @("END")
      option domain-name "lab.example.local";
      option domain-name-servers 8.8.8.8, 8.8.4.4;
      
      default-lease-time 600;
      max-lease-time 7200;
      
      authoritative;
      
      subnet 192.0.2.0 netmask 255.255.255.0 {
        range 192.0.2.100 192.0.2.150;
        option routers 192.0.2.10;
        option broadcast-address 192.0.2.255;
        
        # PXE Boot settings
        next-server 192.0.2.10;
        filename "pxelinux.0";
      }
      
      # Static host entries
      host deb-auto-1 {
        hardware ethernet 0c:2c:9f:32:00:00;
        fixed-address 192.0.2.121;
      }
      
      host deb-auto-2 {
        hardware ethernet 0c:78:68:b8:00:00;
        fixed-address 192.0.2.122;
      }
      | END
    ,
    require => Package['isc-dhcp-server'],
  }
  
  file { '/etc/default/isc-dhcp-server':
    ensure  => file,
    content => "INTERFACESv4=\"ens4\"\nINTERFACESv6=\"\"\n",
    require => Package['isc-dhcp-server'],
  }
  
  service { 'isc-dhcp-server':
    ensure    => running,
    enable    => true,
    subscribe => [File['/etc/dhcp/dhcpd.conf'], File['/etc/default/isc-dhcp-server']],
    require   => [File['/etc/dhcp/dhcpd.conf'], File['/etc/default/isc-dhcp-server']],
  }
  
  # Apache Configuration
  file { '/var/www/html/preseed':
    ensure  => directory,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0755',
    require => Package['apache2'],
  }
  
  file { '/var/www/html/preseed/bookworm.cfg':
    ensure  => file,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    content => @("END")
      # Localization
      d-i debian-installer/locale string sv_SE.UTF-8
      d-i keyboard-configuration/xkb-keymap select se
      
      # Network configuration
      d-i netcfg/choose_interface select auto
      d-i netcfg/get_hostname string debian-auto
      d-i netcfg/get_domain string lab.example.local
      
      # Mirror settings
      d-i mirror/country string manual
      d-i mirror/http/hostname string deb.debian.org
      d-i mirror/http/directory string /debian
      d-i mirror/http/proxy string
      
      # Clock and time zone
      d-i clock-setup/utc boolean true
      d-i time/zone string Europe/Stockholm
      d-i clock-setup/ntp boolean true
      
      # Partitioning
      d-i partman-auto/method string regular
      d-i partman-auto/choose_recipe select atomic
      d-i partman/confirm_write_new_label boolean true
      d-i partman/choose_partition select finish
      d-i partman/confirm boolean true
      d-i partman/confirm_nooverwrite boolean true
      
      # Account setup
      d-i passwd/root-login boolean true
      d-i passwd/root-password password password123
      d-i passwd/root-password-again password password123
      d-i passwd/user-fullname string Debian User
      d-i passwd/username string debian
      d-i passwd/user-password password debian123
      d-i passwd/user-password-again password debian123
      
      # Package selection
      tasksel tasksel/first multiselect standard, ssh-server
      d-i pkgsel/include string sudo curl wget vim htop
      popularity-contest popularity-contest/participate boolean false
      
      # Boot loader
      d-i grub-installer/only_debian boolean true
      d-i grub-installer/bootdev string default
      
      # Finish installation
      d-i finish-install/reboot_in_progress note
      | END
    ,
    require => File['/var/www/html/preseed'],
  }
  
  service { 'apache2':
    ensure  => running,
    enable  => true,
    require => Package['apache2'],
  }
}
