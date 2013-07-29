#
# Download a file from a URL (using curl).
#
# === Parameters
#
# [url] URL to download from. Defaults to $title.
#
# [path] Where to download file to. Should be path to a file, not
#   a directory. Defaults to "/root/${basename($url)}". If a file at
#   $path already exists, it the file will not be downloaded.
#
# [timeout] Seconds to wait before making curl timeout. Defaults to
#   300.
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
  $path    = undef,
  $timeout = 300,
){

  if $::r9util_download_curl_version == undef {
    fail("curl is required to download ${url}")
  }

  if $path == undef {
    $base = basename($url)
    $_path = "/root/${base}"
  }else{
    $_path = $path
  }

  $args = "-L --create-dirs -m ${timeout}"

  exec { "r9util-download-${title}":
    path    => ['/bin','/usr/bin'],
    command => "curl ${args} \"${url}\" -o \"${_path}\"",
    creates => $_path,
  }

}
