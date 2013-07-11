r9util::system_user { 'mytestuser':
# ensure => absent,
  uid  => 905,
# bindir => { 'source' => '/tmp/mytestuserbin' },
# auth_keys => { 'root-for-bamboo' => { 'key' => 'thisisafakekey' } }
}
