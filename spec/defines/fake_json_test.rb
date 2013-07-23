describe 'fake_json_test' do
  let :title do 'notreal' end
  let :pre_condition do
<<PP
define fake_json_test{
  $data = {
    'a' => 1,
    'b' => '2',
    'c' => [true,false,undef,4.3],
  }

  notify { 'plain':
    message => predictable_pretty_json($data),
  }

  notify { 'coerced':
    message => predictable_pretty_json($data,true),
  }
}
PP
  end

  it 'should coax types back out of data that\'s been mangled by Puppet' do
    plain = <<JSON
{
  "a": "1",
  "b": "2",
  "c": [
    true,
    false,
    "undef",
    "4.3"
  ]
}
JSON
    coerced = <<JSON
{
  "a": 1,
  "b": 2,
  "c": [
    true,
    false,
    null,
    4.3
  ]
}
JSON
    should contain_notify('plain').with_message(plain.chomp)
    should contain_notify('coerced').with_message(coerced.chomp)
  end
end
