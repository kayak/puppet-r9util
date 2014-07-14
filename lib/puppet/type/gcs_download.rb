require 'puppet/parameter/boolean'

Puppet::Type.newtype(:gcs_download) do

  @doc = <<-EOF
  Download a file from Google Cloud Storage.

  Example:
    gcs_download { 'my-selenium-download':
      bucket      => 'selenium-release',
      remote_path => '2.41.0/selenium-server-standalone-2.41.0.jar',
      local_path  => '/usr/local/selenium/selenium.jar',
    }

  EOF

  ensurable do
    defaultvalues
    defaultto { :present }
  end

  newparam(:bucket) do
    desc 'The name of the bucket where the file lives'
  end

  newparam(:remote_path) do
    desc 'The path to the file within the bucket'
  end

  newparam(:local_path) do
    desc 'The local path where the file should be downloaded to'
    isnamevar
  end

  newparam(:always_check_md5,
           :boolean => true,
           :parent => Puppet::Parameter::Boolean) do
    desc 'When true, the md5sum of the remote file will be fetched and compared with the local, downloaded copy. By default this check is only performed when the resource is refreshed. Results in a call to the Google Cloud Storage API during every Puppet run on the node.'

    defaultto { :false }
  end

  def refresh
    provider.download_if_md5_mismatch
  end

  validate do
    if self[:ensure] == :present
      if self[:bucket].nil? || self[:remote_path].nil?
        fail 'bucket and remote_path parameters are required!'
      end
    end
  end
end
