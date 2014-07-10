
$md5sum      = '00042f9912c55a6191d7b3fe01239135'
$testfile1   = '/tmp/my-gcs-test-download-1.jar'
$testfile2   = '/tmp/my-gcs-test-download-2.jar'
$bucket      = 'selenium-release'
$remote_path = '2.41/selenium-server-standalone-2.41.0.jar'

# Test present
gcs_download { $testfile1:
  remote_path => $remote_path,
  bucket      => $bucket,
}
->
exec { "check-${testfile1}-md5sum":
  command => "echo '${md5sum}  ${testfile1}' | md5sum -c",
}
->
exec { "clean-up-${testfile1}":
  command => "rm -f ${testfile1}",
}

# Test absent
exec { 'touch-testfile2':
  command => "touch ${testfile2}",
}
->
gcs_download { $testfile2:
  ensure     => absent,
}
->
exec { 'check-testfile2-absent':
  command => "test ! -f ${testfile2}",
}

Exec <||> {
  path => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
}
