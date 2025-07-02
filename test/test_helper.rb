# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ubl"

def display_validation_errors(errors)
  errors.each do |e|
    puts e
  end
end
