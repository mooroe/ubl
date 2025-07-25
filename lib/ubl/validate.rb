require "nokogiri"
require "date"
require "fileutils"
require "colorize"
require_relative "constants"

module Ubl
  class Validator
    def initialize(extension: nil, schematron: true)
      @ubl_be = extension == UBL_BE
      @schematron = schematron
    end

    def validate_invoice(path)
      xsd = File.join(__dir__, "../../xsd/maindoc/UBL-Invoice-2.1.xsd")
      validate(path, xsd)
    end

    def validate_credit_note(path)
      xsd = File.join(__dir__, "../../xsd/maindoc/UBL-CreditNote-2.1.xsd")
      validate(path, xsd)
    end

    private

    def validate(path, xsd)
      ubl_content = File.read(path)
      errors = validate_xsd(ubl_content, xsd)
      return errors if errors.any?

      errors = validate_schematron(path) if @schematron

      errors
    end

    def validate_xsd(xml_content, xsd)
      return ["XSD not found: #{xsd}"] unless File.exist?(xsd)

      begin
        xml_doc = Nokogiri::XML(xml_content)
        xsd_doc = Nokogiri::XML::Schema(File.open(xsd))
        errors = xsd_doc.validate(xml_doc)
        errors.map(&:message)
      rescue => e
        ["XSD validation error: #{e.message}"]
      end
    end

    def validate_schematron(invoice_file)
      env = @ubl_be ? "-e UBL_BE=true" : ""
      cmd = "docker run --rm #{env} -v #{invoice_file}:/app/invoice.xml:ro ghcr.io/mooroe/peppol_schematron:latest 2>/dev/null"
      # puts cmd
      svrl_content = `#{cmd}`
      parse_svrl_errors(svrl_content)
    end

    def get_svrl_errors(svrl_doc, flag, color)
      errors = []
      svrl_doc.xpath("//failed-assert[@flag=\"#{flag}\"]").each do |node|
        test = node["test"].squeeze(" ")
        # location = node['location']
        text = node.xpath("text").map(&:content).join(" ").tr("\n", " ").squeeze(" ").strip
        errors << flag.colorize(color) + ": #{text}\n       #{test.colorize(:grey)}"
      end
      errors
    end

    # Parse SVRL (Schematron Validation Report Language) output for errors
    def parse_svrl_errors(svrl_content)
      svrl_doc = Nokogiri::XML(svrl_content)
      svrl_doc.remove_namespaces!
      errors = []
      errors << get_svrl_errors(svrl_doc, "fatal", :red)
      errors << get_svrl_errors(svrl_doc, "warning", :light_red)
      errors.flatten
    end
  end
end
