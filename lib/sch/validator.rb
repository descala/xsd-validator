require 'nokogiri'
require 'schematron'

module Sch
  module Validator

    CBC = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"

    class ValidationError < RuntimeError
    end

    def sch_validate(doc)
      errors = []
      schematrons(doc).each do |schematron_file|
        cache_xslt = "lib/sch/compiled/#{File.basename(schematron_file)}.xslt"
        if File.exists?(cache_xslt)
          compiled_schematron = File.read(cache_xslt)
        else
          compiled_schematron = Schematron::XSLT2.compile(File.read(schematron_file))
          File.write(cache_xslt, compiled_schematron)
        end
        validation_result = Schematron::XSLT2.validate(compiled_schematron, doc)
        errors = errors + Schematron::XSLT2.get_errors(validation_result)
      end
      return errors
    end

    def sch_validate!(doc)
      errors = sch_validate(doc)
      raise ValidationError.new(errors.join("\n")) if errors.any?
      return true
    end

    def schematrons(doc)
      doc_nokogiri =Nokogiri::XML(doc) unless doc.is_a? Nokogiri::XML::Document
      # Assume UBL
      customization_id = doc_nokogiri.xpath('//cbc:CustomizationID', cbc: CBC).text
      case customization_id
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0'
        %w(lib/sch/schemas/CEN-EN16931-UBL.sch lib/sch/schemas/PEPPOL-EN16931-UBL.sch)
      when 'urn:cen.eu:en16931:2017#conformant#urn:fdc:peppol.eu:2017:poacc:billing:international:aunz:3.0'
        %w(lib/sch/schemas/AUNZ-UBL-validation.sch lib/sch/schemas/AUNZ-PEPPOL-validation.sch)
      else
        raise StandardError.new("Unkown CustomizationID '#{customization_id}'")
      end
    end

    # Creates compiled xslt
    def self.compile
      Dir.chdir('lib/sch/schemas/') do
        Dir["**/*.sch"].each do |schematron_file|
          cache_xslt = "../compiled/#{File.basename(schematron_file)}.xslt"
          compiled_schematron = Schematron::XSLT2.compile(File.read(schematron_file))
          File.write(cache_xslt, compiled_schematron)
        end
      end
    end
  end
end
