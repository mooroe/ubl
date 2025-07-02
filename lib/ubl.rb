require_relative "ubl/builder"

##
# The Invoice and CreditNote class generates UBL (Universal Business Language) compliant XML
# documents following PEPPOL standards.
module Ubl
  class Invoice < UblBuilder
    ##
    # Creates a new Invoice instance.
    #
    # == Parameters
    # * +extension+ - (String) Optional. Set to +"UBL_BE"+ to generate UBL.BE compliant invoices
    #   for Belgian requirements. Defaults to +nil+ for standard PEPPOL format.
    #
    def initialize(extension = nil)
      super
    end

    def build
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.Invoice(namespaces) do
          build_header(xml) do |xml|
            xml["cbc"].InvoiceTypeCode "380"
          end

          build_document_reference(xml, "CommercialInvoice")

          build_party(xml, @supplier, "AccountingSupplierParty")
          build_party(xml, @customer, "AccountingCustomerParty")

          build_tax_total(xml)
          build_monetary_total(xml)
          build_invoice_lines(xml)
        end
      end
      builder.to_xml
    end
  end

  class CreditNote < UblBuilder
    ##
    # Creates a new CreditNote instance.
    #
    # == Parameters
    # * +extension+ - (String) Optional. Set to +"UBL_BE"+ to generate UBL.BE compliant
    #   credit notes for Belgian requirements. Defaults to +nil+ for standard PEPPOL format.
    #
    def initialize(extension = nil)
      super
    end

    def build
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.CreditNote(namespaces.merge("xmlns" => "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2")) do
          build_header(xml) do |xml|
            xml["cbc"].CreditNoteTypeCode "381"
          end

          build_document_reference(xml, "CreditNote")

          build_party(xml, @supplier, "AccountingSupplierParty")
          build_party(xml, @customer, "AccountingCustomerParty")

          build_tax_total(xml)
          build_monetary_total(xml)
          build_invoice_lines(xml)
        end
      end
      builder.to_xml
    end
  end
end
