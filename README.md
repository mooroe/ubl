# Ubl

Generate and validate UBL (Universal Business Language) documents, such as invoices and credit notes, compliant with the Peppol network.

## installation

install the gem and add to the application's gemfile by executing:

```bash
bundle add ubl
```

if bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install ubl
```

## Example

```ruby
require "ubl"

invoice = Ubl::Invoice.new
invoice.invoice_nr = "INV-2025-001"
invoice.pdffile = "./invoice.pdf"

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

invoice.add_line(name: "Consulting Services", quantity: 10, unit_price: 100.0, tax_rate: 21.0)
invoice.add_line(name: "Software License", quantity: 1, unit_price: 500.0, tax_rate: 21.0)

invoice.build
```

If you need the UBL.BE version:
```ruby
invoice = Ubl::Invoice.new("UBL_BE")
```

You can also validate the result. 
You need Docker for the schematron validation. (https://github.com/mooroe/peppol_schematron)
With `schematron: false` you can disable this and only the xsd validation will run.
```ruby
Tempfile.create("invoice.xml") do |invoice_file|
  File.write(invoice_file, content)
  p Ubl.validate_invoice(invoice_file.path, extension: "UBL_BE", schematron: true)
end
```

## development

after checking out the repo, run `bin/setup` to install dependencies. then, run `rake test` to run the tests. you can also run `bin/console` for an interactive prompt that will allow you to experiment.

to install this gem onto your local machine, run `bundle exec rake install`. to release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## contributing

bug reports and pull requests are welcome on github at https://github.com/mooroe/ubl.

## license

the gem is available as open source under the terms of the [mit license](https://opensource.org/licenses/mit).
