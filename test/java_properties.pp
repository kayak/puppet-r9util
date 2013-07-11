$testfile = '/tmp/java_properties_test.properties'

file { $testfile:
  ensure => present,
}
->
r9util::java_properties { $testfile:
  properties => {
    'prop.1'       => 'foo',
    'prop.2'       => 'something with spaces',
    'singlequotes' => '\'test\'',
    'doublequotes' => '"test"',
  },
}
