# frozen_string_literal: true

require "test_helper"

def create_invoice(extension = nil)
  invoice = Ubl::Invoice.new(extension)
  invoice.invoice_nr = "INV-2025-001"
  invoice.pdffile = __dir__ + "/invoice_test.pdf"

  invoice.add_supplier(
    name: "ACME Corp",
    country: "BE",
    vat_id: "BE0123456749",
    address: "Main Street 123",
    city: "Brussels",
    postal_code: "1000"
  )

  invoice.add_customer(
    name: "Customer Ltd",
    country: "BE",
    vat_id: "BE0123456749",
    address: "Customer Lane 456",
    city: "Antwerpen",
    postal_code: "1012"
  )

  invoice.add_payment_means(iban: "BE1234567891234", bic: "GEBABEBB")

  invoice.add_line(name: "Consulting", description: "More consulting", quantity: 10, unit_price: 100.0, tax_rate: 21.0)
  invoice.add_line(name: "Software License", quantity: 1, unit_price: 500.0, tax_rate: 21.0)

  invoice
end

class TestUbl < Minitest::Test
  def test_sum
    invoice = create_invoice
    tax = 10 * 100 * 0.21 + 1 * 500 * 0.21
    assert_equal tax, invoice.tax_total
    assert_equal 1000 + 500 + tax, invoice.legal_monetary_total
  end

  def test_valid_invoice
    invoice = create_invoice
    content = invoice.build
    Tempfile.create("invoice.xml") do |invoice_file|
      File.write(invoice_file, content)
      errors = Ubl.validate_invoice(invoice_file.path)
      display_validation_errors(errors)
      assert_equal 0, errors.length
    end
  end

  def test_valid_be_invoice
    extension = "UBL_BE"
    invoice = create_invoice(extension)
    content = invoice.build
    Tempfile.create("invoice.xml") do |invoice_file|
      File.write(invoice_file, content)
      errors = Ubl.validate_invoice(invoice_file.path, extension:)
      display_validation_errors(errors)
      assert_equal 0, errors.length
    end
  end
end
