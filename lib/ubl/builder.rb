# frozen_string_literal: true

require "nokogiri"
require "date"
require "base64"
require_relative "constants"

module Ubl
  class UblBuilder
    attr_accessor :invoice_nr, :issue_date, :due_date, :currency, :supplier,
      :customer, :invoice_lines, :tax_total, :legal_monetary_total, :pdffile

    def initialize(extension = nil)
      @ubl_be = extension == UBL_BE
      @issue_date = Date.today
      @due_date = @issue_date + 30
      @currency = "EUR"
      @attachments = []
      @invoice_lines = []
      @tax_total = 0
      @legal_monetary_total = 0
    end

    def namespaces
      {
        "xmlns" => "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
        "xmlns:cac" => "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
        "xmlns:cbc" => "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
      }
    end

    def add_supplier(name:, country:, vat_id: nil, address: nil, city: nil, postal_code: nil)
      @supplier = {
        name: name,
        country: country,
        vat_id: vat_id,
        address: address,
        city: city,
        postal_code: postal_code
      }
    end

    def add_customer(name:, country:, vat_id: nil, address: nil, city: nil, postal_code: nil)
      @customer = {
        name: name,
        country: country,
        vat_id: vat_id,
        address: address,
        city: city,
        postal_code: postal_code
      }
    end

    def add_line(name:, quantity:, unit_price:, tax_rate: 21.0, unit: "ZZ")
      line_extension_amount = (quantity * unit_price).round(2)
      tax_amount = (line_extension_amount * (tax_rate / 100.0)).round(2)

      @invoice_lines << {
        id: (@invoice_lines.length + 1).to_s,
        name: name,
        quantity: quantity,
        unit: unit,
        unit_price: unit_price,
        line_extension_amount: line_extension_amount,
        tax_rate: tax_rate,
        tax_amount: tax_amount
      }

      calculate_totals
    end

    private

    def calculate_totals
      line_extension_amount = @invoice_lines.sum { |line| line[:line_extension_amount] }
      @tax_total = @invoice_lines.sum { |line| line[:tax_amount] }
      @legal_monetary_total = line_extension_amount + @tax_total
    end

    def build_header(xml)
      xml["cbc"].CustomizationID @ubl_be ? CUSTOMIZATION_UBL_BE : CUSTOMIZATION_ID
      xml["cbc"].ProfileID PROFILE_ID
      xml["cbc"].ID @invoice_nr
      xml["cbc"].IssueDate @issue_date.to_s
      xml["cbc"].DueDate @due_date.to_s
      yield xml
      xml["cbc"].DocumentCurrencyCode @currency
      xml["cac"].OrderReference do
        xml["cbc"].ID @invoice_nr
      end
    end

    def build_document_reference(xml, description)
      if @ubl_be
        xml["cac"].AdditionalDocumentReference do
          xml["cbc"].ID "UBL.BE"
          xml["cbc"].DocumentDescription description
        end
      end

      if @pdffile
        content = Base64.strict_encode64(File.binread(@pdffile))

        xml["cac"].AdditionalDocumentReference do
          xml["cbc"].ID @invoice_nr
          xml["cbc"].DocumentDescription "PDF"
          xml["cac"].Attachment do
            xml["cbc"].EmbeddedDocumentBinaryObject(mimeCode: "application/pdf", filename: File.basename(@pdffile)) { xml.text content }
          end
        end
      end
    end

    def add_attachment(id, filename)
      @attachments << {id: id, content:}
    end

    def build_party(xml, party_data, party_type)
      return unless party_data

      xml["cac"].send(party_type) do
        xml["cac"].Party do
          xml["cbc"].EndpointID(schemeID: "0208") { xml.text party_data[:vat_id].gsub(/^[A-Za-z]+/, "") }

          if party_data[:address]
            xml["cac"].PostalAddress do
              xml["cbc"].StreetName party_data[:address] if party_data[:address]
              xml["cbc"].CityName party_data[:city] if party_data[:city]
              xml["cbc"].PostalZone party_data[:postal_code] if party_data[:postal_code]
              xml["cac"].Country do
                xml["cbc"].IdentificationCode party_data[:country]
              end
            end
          end

          if party_data[:vat_id]
            xml["cac"].PartyTaxScheme do
              xml["cbc"].CompanyID party_data[:vat_id]
              xml["cac"].TaxScheme do
                xml["cbc"].ID "VAT"
              end
            end
          end

          xml["cac"].PartyLegalEntity do
            xml["cbc"].RegistrationName party_data[:name]
          end
        end
      end
    end

    def build_invoice_lines(xml)
      @invoice_lines.each do |line|
        xml["cac"].InvoiceLine do
          xml["cbc"].ID line[:id]
          xml["cbc"].InvoicedQuantity(unitCode: line[:unit]) { xml.text line[:quantity] }
          xml["cbc"].LineExtensionAmount(currencyID: @currency) { xml.text sprintf("%.2f", line[:line_extension_amount]) }

          if @ubl_be
            xml["cac"].TaxTotal do
              xml["cbc"].TaxAmount(currencyID: @currency) { xml.text line[:tax_amount] }
            end
          end

          xml["cac"].Item do
            xml["cbc"].Name line[:name]
            xml["cac"].ClassifiedTaxCategory do
              xml["cbc"].ID get_tax_category_id(line[:tax_rate])
              xml["cbc"].Name get_tax_category_name(line[:tax_rate]) if @ubl_be
              xml["cbc"].Percent line[:tax_rate]
              xml["cac"].TaxScheme do
                xml["cbc"].ID "VAT"
              end
            end
          end

          xml["cac"].Price do
            xml["cbc"].PriceAmount(currencyID: @currency) { xml.text sprintf("%.2f", line[:unit_price]) }
          end
        end
      end
    end

    def get_tax_category_name(tax_rate)
      case tax_rate
      when 0, "0%"
        "00"
      when 6, "6%"
        "01"
      when 12, "12%"
        "02"
      when 21, "21%"
        "03"
      else
        "00" # Default to 0% category
      end
    end

    def get_tax_category_id(tax_rate)
      case tax_rate
      when 0, "0%"
        "Z"
      when 6, "6%"
        "S"
      when 12, "12%"
        "S"
      when 21, "21%"
        "S"
      else
        "Z" # Default to 0% category
      end
    end

    def build_tax_total(xml)
      return if @invoice_lines.empty?

      xml["cac"].TaxTotal do
        xml["cbc"].TaxAmount(currencyID: @currency) { xml.text sprintf("%.2f", @tax_total) }

        # Group by tax rate
        tax_groups = @invoice_lines.group_by { |line| line[:tax_rate] }

        tax_groups.each do |tax_rate, lines|
          taxable_amount = lines.sum { |line| line[:line_extension_amount] }
          tax_amount = lines.sum { |line| line[:tax_amount] }

          xml["cac"].TaxSubtotal do
            xml["cbc"].TaxableAmount(currencyID: @currency) { xml.text sprintf("%.2f", taxable_amount) }
            xml["cbc"].TaxAmount(currencyID: @currency) { xml.text sprintf("%.2f", tax_amount) }
            xml["cac"].TaxCategory do
              xml["cbc"].ID get_tax_category_id(tax_rate)
              xml["cbc"].Name get_tax_category_name(tax_rate) if @ubl_be
              xml["cbc"].Percent tax_rate
              xml["cac"].TaxScheme do
                xml["cbc"].ID "VAT"
              end
            end
          end
        end
      end
    end

    def build_monetary_total(xml)
      return if @invoice_lines.empty?

      line_extension_amount = @invoice_lines.sum { |line| line[:line_extension_amount] }

      xml["cac"].LegalMonetaryTotal do
        xml["cbc"].LineExtensionAmount(currencyID: @currency) { xml.text sprintf("%.2f", line_extension_amount) }
        xml["cbc"].TaxExclusiveAmount(currencyID: @currency) { xml.text sprintf("%.2f", line_extension_amount) }
        xml["cbc"].TaxInclusiveAmount(currencyID: @currency) { xml.text sprintf("%.2f", @legal_monetary_total) }
        xml["cbc"].PayableAmount(currencyID: @currency) { xml.text sprintf("%.2f", @legal_monetary_total) }
      end
    end
  end
end
