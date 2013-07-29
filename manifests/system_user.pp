# A generic system user definition. Bundles user and group together
# with some convenient other options.
#
# === Parameters
#
# [title] The username for this user.
#
# [uid] Uid for this user. This parameter is not required, but setting
#   it explicitly is strongly encouraged.
#
# [homedir] Path to user's home directory. Defaults to "/home/${title}".
#
# [shell] Login shell for this user. Defaults to "/sbin/nologin".
#
# [group] Name of the user's primary group. Defaults to $title. Will
#   be declared with Puppet's group type.
#
# [groups] A list of any extra groups the user should belong to. Will
#   not be declared. Defaults to []
#
# [gid] Gid for this user's primary group. Defaults to $uid
#
# [passwd] Password hash for this user. Defaults to "!"
#
# [bindir] A hash of options configuring a directory of scripts that
#   should be copied to $homedir/bin. Default does nothing.
#
# [auth_keys] A hash of ssh authorized key resource definitions that
#   should be set for this user. Defaults to {}.
#
# [managehome] Whether Puppet should manage $homedir. Defaults to true.
#
# [ensure] Valid values are present, absent. Defaults to present. When
#   set to absent, the user, group, and any related resources will be
#   removed.
#
#
# === Examples
#
# Simplest usage:
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
#     'source' => 'puppet://modules/bamboo/bin',
#     'purge'  => 'true'
#   }
# }
#
# To specify a set of authorized ssh login keys for this user:
#
# r9util::system_user { 'bamboo':
#   uid       => '476',
#   auth_keys => {
#      'root-for-bamboo' => { 'key' => 'AAAAB3Nz...' },
#   }
# }
#
define r9util::system_user(
  $uid        = undef,
  $homedir    = "/home/${title}",
  $shell      = '/sbin/nologin',
  $group      = $title,
  $groups     = [],
  $gid        = undef,
  $passwd     = '!',
  $bindir     = {
    source => undef,
    purge  => false,
  },
  $auth_keys  = {},
  $managehome = true,
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
