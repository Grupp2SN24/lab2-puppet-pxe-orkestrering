# Main manifest
node default {
  # Default configuration
}

node 'pxe-server' {
  include role::provisioner
}

node 'deb-auto-1' {
  include role::linux::base
}

node 'deb-auto-2' {
  include role::linux::base
}
