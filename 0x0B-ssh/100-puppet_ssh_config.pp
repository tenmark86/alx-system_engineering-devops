# set up your client SSH configuration file so that you can connect
# to a server without typing a password.

include stdlib
file_line {'change private key':
  ensure => present,
  path   => '/etc/ssh/ssh_config',
  line   => 'IdentityFile ~/.ssh/school'
}
file_line {'no password':
  ensure => present,
  path   => '/etc/ssh/ssh_config',
  line   => 'PasswordAuthentication no',
}
