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
