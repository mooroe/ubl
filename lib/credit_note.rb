require_relative "ubl/builder"

module Ubl
  class CreditNote < UblBuilder
    def initialize(ubl_be)
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
