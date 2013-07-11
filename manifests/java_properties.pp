# In-place editing of java properties files with Augeas.
# Property values with spaces should be quoted.
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
