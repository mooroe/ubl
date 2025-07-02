# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ubl"

def validate_invoice(ubl_file_path, extension)
  errors = Ubl.validate_invoice(ubl_file_path, extension)
  errors.each do |e|
    p e
  end
  errors
end
