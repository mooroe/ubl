# frozen_string_literal: true

require "test_helper"
require "ubl/version"

class TestUbl < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Ubl::VERSION
  end
end
