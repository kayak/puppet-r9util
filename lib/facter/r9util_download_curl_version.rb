# A hacky way of determining the version of curl that is present on the machine.
#
# Primarily used to determine if curl is actually installed, before
# trying to download files with it.
require 'facter'

Facter.add('r9util_download_curl_version') do
  setcode do
    output = `curl --version 2>/dev/null`
    $?.success? ? output.split[1] : nil
  end
end
