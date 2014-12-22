require 'test_helper'

require 'set'

require 'dnsync/record'

class RecordTest < Minitest::Test
  def test_equality
    a1 = Dnsync::Record.new("record1", "a", 300, [ Dnsync::Answer.new("127.0.0.1", nil) ])
    a2 = Dnsync::Record.new("record1", "a", 300, [ Dnsync::Answer.new("127.0.0.1", nil) ])

    assert a1 == a2
  end

  def test_inequality
    a1 = Dnsync::Record.new("record1", "a", 300, [ Dnsync::Answer.new("127.0.0.1", nil) ])
    a2 = Dnsync::Record.new("record1", "a", 300, [ Dnsync::Answer.new("127.0.0.1", nil) ])

    assert !(a1 != a2)
  end

  def test_spaceship
    a1 = Dnsync::Record.new("record1", "a", 300, [ Dnsync::Answer.new("127.0.0.1", nil) ])
    a2 = Dnsync::Record.new("record1", "a", 300, [ Dnsync::Answer.new("127.0.0.1", nil) ])

    assert (a1 <=> a2) == 0
  end
end