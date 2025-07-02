require "nokogiri"
require "date"
require "fileutils"
require "colorize"

class UBLValidator
  def initialize
    @xsd = File.join(__dir__, "./xsd/maindoc/UBL-Invoice-2.1.xsd")
  end

  # XSD and Schematron validation
  def validate_full(invoice_file, ubl_be = false)
    ubl_xml = File.read(invoice_file)

    errors = validate_xsd(ubl_xml)
    return errors if errors.any?

    env = ubl_be ? "-e UBL_BE=true" : ""

    cmd = "docker run --rm #{env} -v #{invoice_file}:/app/invoice.xml:ro ghcr.io/roel4d/peppol_schematron:latest 2>/dev/null"
    puts cmd

    svrl_content = `#{cmd}`
    parse_svrl_errors(svrl_content)
  end

  private

  # Validate UBL XML against XSD schema
  def validate_xsd(xml_content)
    return ["XSD not found: #{@xsd}"] unless File.exist?(@xsd)

    begin
      xml_doc = Nokogiri::XML(xml_content)
      xsd_doc = Nokogiri::XML::Schema(File.open(@xsd))
      errors = xsd_doc.validate(xml_doc)
      errors.map(&:message)
    rescue => e
      ["XSD validation error: #{e.message}"]
    end
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

if __FILE__ == $0
  invoice = ARGV[0]
  validator = UBLValidator.new
  errors = validator.validate_full(invoice || "invoice.xml")
  errors.each do |e|
    puts e
  end
end
