# A hacky way of determining the path to the CD_Properties.lns file

__lens__ = File.expand_path('../../augeas/lenses/cd_properties.aug',__FILE__)

if File.exists?(__lens__)
  require 'facter'

  Facter.add('r9util_properties_lens_path') do
    setcode do File.dirname(__lens__) end
  end
end
