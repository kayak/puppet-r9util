# A generic system user. Eg. bamboo, puppet, etc.
#
# Simplest usage is:
#
# r9util::system_user { 'bamboo':
#   uid => '476'
# }
#
# Which would:
#   - create the bamboo user and group with uid and gid of 476
#   - set the home directory to /home/bamboo
#   - create /home/bamboo and copy over /etc/skel files if they do not
#       already exist
#   - set login shell to /sbin/nologin
#
# To specify a set of scripts to copy to the user's ~/bin directory:
#
# r9util::system_user { 'bamboo':
#   uid    => '476',
#   bindir => {
#     'source' => 'puppet://modules/bamboo/bin'
#     'purge'  => 'true'
#   }
# }
#
# To specify a set of authorized ssh login keys for this user:
#
# r9util::system_user { 'bamboo':
#   uid       => '476',
#   auth_keys => {
#      'root-for-bamboo' => { 'key' => 'AAAAB3Nz<...snip...>' },
#   }
# }
#
#
define r9util::system_user(
  $uid        = undef,       # uid for this user
  $homedir    = "/home/${title}", # home directory - default is "/home/${user}"
  $shell      = '/sbin/nologin', # login shell
  $group      = $title,      # name of user's primary group
  $groups     = [],          # any extra groups this user should belong to
  $gid        = undef,       # gid for this user's primary group
  $passwd     = '!',         # password hash
  $bindir     = {            # scripts to copy to $homedir/bin
    source => undef,         #   puppet url pointing to scripts
    purge  => false,
  },
  $auth_keys  = {},          # ssh authorized keys for this user
  $managehome = true,        # whether to create home dir
  $ensure     = present,
){

  $user = $title

  user { $user:
    ensure     => $ensure,
    allowdupe  => false,
    home       => $homedir,
    managehome => $managehome,
    comment    => $title,
    gid        => $group,
    groups     => $groups,
    password   => $passwd,
    shell      => $shell,
    system     => true,
    uid        => $uid,
  }

  $gid_param = $gid ? {
    undef => $uid,
    default => $gid,
  }

  group { $group:
    ensure    => $ensure,
    allowdupe => false,
    gid       => $gid_param,
    system    => true,
  }

  if $ensure == 'absent' {
    User[$user] -> Group[$group]
  }else{

    if $managehome {

      $ssh_authkey_defaults = {
        user    => $user,
        type    => 'ssh-rsa',
      }

      create_resources('ssh_authorized_key',$auth_keys,$ssh_authkey_defaults)

      if $bindir['source'] != undef {

        file { "${homedir}/bin":
          ensure  => directory,
          recurse => true,
          purge   => $bindir['purge'],
          source  => $bindir['source'],
          group   => $group,
          owner   => $user,
          mode    => '0755',
        }
      }

    }
  }

}
