require 'test_helper'

require 'set'

require 'dnsync/record_identifier'

class RecordIdentifierTest < Minitest::Test
  def test_equality
    a1 = Dnsync::RecordIdentifier.new("record1", "A")
    a2 = Dnsync::RecordIdentifier.new("record1", "A")

    assert a1 == a2
  end

  def test_eql
    a1 = Dnsync::RecordIdentifier.new("record1", "A")
    a2 = Dnsync::RecordIdentifier.new("record1", "A")

    assert a1.eql?(a2)
  end

  def test_spaceship
    a1 = Dnsync::RecordIdentifier.new("record1", "A")
    a2 = Dnsync::RecordIdentifier.new("record1", "A")

    assert (a1 <=> a2) == 0
  end

  def test_array_subtract
    a1 = Dnsync::RecordIdentifier.new("record1", "A")
    a2 = Dnsync::RecordIdentifier.new("record1", "A")

    assert [a1] - [a2] == []
  end
end