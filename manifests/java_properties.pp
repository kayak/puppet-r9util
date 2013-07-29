#
# In-place editing of Java properties files with Augeas, using
# Craig Dunn's Properties lens.
#
# === Parameters
#
# [path] The path to the file where properties should be set. Defaults
#   to resource title.
#
# [properties] A hash of property names and values that should be
#   set. If a property name is already defined in the file, the value
#   will be updated accordingly; properties that are not defined will
#   be added at the end of the file.
#
# [auto_quote] Whether to try to automatically quote property values with
#   spaces or quotes in them, before passing them to Augeas. Defaults
#   to true. Most people won't need to change this parameter.
#
# === Examples
#
# r9util::java_properties { '/tmp/my.properties':
#   properties => {
#     'a.number'        => '1',
#     'my.message'      => 'Hello, world!',
#     'some.property.1' => '"a quoted string"',
#   }
# }
#
# will add the following to /tmp/my.properties:
#
# a.number=1
# my.message=Hello, world!
# some.property.1="a quoted string"
#
# ==== Note
#
# There is currently no way to purge previously-set properties from
# files, if you have an interest in this capability please open an
# issue.
#
define r9util::java_properties(
  $path = $title,
  $properties = {},
  $auto_quote = true,
){
  validate_hash($properties)

  $tmp_props = $auto_quote ? {
    true => quote_properties($properties),
    default => $properties,
  }

  $properties_array = sort(join_keys_to_values($tmp_props,' '))
  $changes = prefix($properties_array,'set ')

  $augtitle = "update-${path}-properties"

  augeas { $augtitle:
    lens      => 'CD_Properties.lns',
    incl      => $path,
    changes   => $changes,
  }

  if $::r9util_properties_lens_path != undef {
    Augeas[$augtitle] {
      load_path => $::r9util_properties_lens_path,
    }
  }
}
