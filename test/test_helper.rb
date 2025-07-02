# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "validate"
require "ubl"

def validate(ubl_file_path, ubl_be)
  validator = UBLValidator.new
  errors = validator.validate_full(ubl_file_path, ubl_be)
  errors.each do |e|
    p e
  end
  errors
end
