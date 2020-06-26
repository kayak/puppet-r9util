#
# Download a file from a URL (using wget).
#
# === Parameters
#
# [url] URL to download from. Defaults to $title.
#
# [path] Where to download file to. Should be path to a file, not
#   a directory. Defaults to "/root/${basename($url)}". If a file at
#   $path already exists, it the file will not be downloaded.
#
# [timeout] Seconds to wait before making wget timeout. Defaults to
#   300.
#
# [md5sum] md5sum to verify. No md5sum check is performed.
#
# === Examples
#
# r9util::download { 'download-foo':
#   url  => 'http://www.example.com/myfile.tar.gz',
#   path => '/tmp/myfile.tar.gz',
# }
#
# will download http://www.example.com/myfile.tar.gz to /tmp
#
define r9util::download(
  $url     = $title,
  $timeout = '300',
  $path    = undef,
  $md5sum  = undef,
){

  ensure_packages(['wget'])

  if $path == undef {
    $base = basename($url)
    $_path = "/root/${base}"
  }else{
    $_path = $path
  }

  $args = ['-T', "$timeout", '-O', $_path]

  exec { "r9util-download-${title}":
    path    => ['/bin', '/usr/bin'],
    command => shellquote('wget', $args, $url),
  }

  if $md5sum == undef {

    Exec["r9util-download-${title}"] { creates => $_path }

  } else {
    $md5check_input = shellquote("${md5sum}  ${path}")
    $md5check = "echo ${md5check_input} | md5sum --check"

    Exec["r9util-download-${title}"] { unless => $md5check }

    exec { "r9util-download-${title}-md5check":
      path        => ['/bin', '/usr/bin'],
      command     => $md5check,
      refreshonly => true,
      subscribe   => Exec["r9util-download-${title}"],
    }
  }
}
