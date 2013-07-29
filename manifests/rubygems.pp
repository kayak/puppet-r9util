#
# This class just installs rubygems.
#
class r9util::rubygems {
  package { 'rubygems':
    ensure => installed,
  }
}
