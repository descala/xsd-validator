require 'nokogiri'
require_relative '../../vendor/schematron-wrapper-saxon11/lib/schematron'

module Sch
  module Validator

    CBC = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
    RAM = "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"

    class ValidationError < RuntimeError
    end

    class ValidationWarning < RuntimeError
    end

    class ResultHandler
      def initialize(validation_result)
        @document = Nokogiri::XML(validation_result) do |config|
          config.options = Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::NOENT
        end
      end

      def errors
        build_result('fatal')
      end

      def warnings
        build_result('warning')
      end

      def build_result(flag)
        result = []
        @document.xpath("//svrl:failed-assert[@flag='#{flag}']|//svrl:successful-report[@flag='#{flag}']").each do |element|
          h = element.attributes.map{|k,v| [k, v.to_s]}.to_h
          h.delete('test')
          description = element.xpath('./svrl:text').text.strip
          if description !~ /#{h['id']}/
            description = "[#{h['id']}] #{description}"
          end
          result << "#{flag.upcase}: #{description} #{h}"
        end
        result
      end
    end

    def sch_validate(doc)
      errors = []
      warnings = []
      schematrons(doc).each do |schematron_file|
        compiled_schematron = File.read(xslt_path(schematron_file))
        validation_result = Schematron::XSLT2.validate(compiled_schematron, doc)
        result_handler = ResultHandler.new(validation_result)
        errors += result_handler.errors
        warnings = warnings + result_handler.warnings
      end
      return errors, warnings
    end

    def sch_validate!(doc)
      errors, warnings = sch_validate(doc)
      raise ValidationError.new((errors+warnings).join("\n")) if errors.any?
      raise ValidationWarning.new(warnings.join("\n")) if warnings.any?
      return true
    end

    def schematrons(doc)
      if doc.is_a? Nokogiri::XML::Document
        doc_nokogiri = doc
      else
        doc_nokogiri = Nokogiri::XML(doc)
      end
      # Assume UBL or CII
      customization_id = doc_nokogiri.xpath('//cbc:CustomizationID', cbc: CBC).text
      if customization_id.empty?
        customization_id = doc_nokogiri.xpath('//ram:GuidelineSpecifiedDocumentContextParameter/ram:ID', ram: RAM).text
      end
      case customization_id
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0'
        %w(CEN-EN16931-UBL.sch PEPPOL-EN16931-UBL.sch)
      when 'urn:cen.eu:en16931:2017#conformant#urn:fdc:peppol.eu:2017:poacc:billing:international:aunz:3.0'
        %w(AUNZ-UBL-validation.sch AUNZ-PEPPOL-validation.sch)
      when 'urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended:urn:www.peppol.eu:bis:peppol5a:ver2.0'
        %w(BIICORE-UBL-T10.sch BIIRULES-UBL-T10.sch OPENPEPPOLCORE-UBL-T10.sch OPENPEPPOL-UBL-T10.sch)
      when 'urn:cen.eu:en16931:2017#conformant#urn:fdc:peppol.eu:2017:poacc:billing:international:sg:3.0'
        %w(SG-Billing3-UBL.sch SG-Subset-CEN-EN16931-UBL.sch SG-Subset-PEPPOL-EN16931-UBL.sch)

      # PEPPOL Message Level Response 3.0 (T71)
      when 'urn:fdc:peppol.eu:poacc:trns:mlr:3'
        %w(PEPPOLBIS-T71.sch)

      # PEPPOL Invoice Response 3.0 (T111)
      when 'urn:fdc:peppol.eu:poacc:trns:invoice_response:3'
        %w(PEPPOLBIS-T111.sch)

      # PEPPOL Despatch Advice transaction 3.1 (T16)
      when 'urn:fdc:peppol.eu:poacc:trns:despatch_advice:3'
        %w(PEPPOLBIS-T16.sch)

      # XRechnung UBL / CII
      when 'urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_2.0', 'urn:cen.eu:en16931#compliant#factur-x.eu:1p0:basic'
        if doc_nokogiri.root.name == 'Invoice'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-Invoice_2.0.sch)
        elsif doc_nokogiri.root.name == 'CreditNote'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-CreditNote_2.0.sch)
        else # CII
          %w(CEN-EN16931-UBL.sch EN16931-CII-validation.sch)
        end

      # XRechnung UBL 2.1
      when 'urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_2.1'
        if doc_nokogiri.root.name == 'Invoice'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-Invoice_2.1.sch)
        elsif doc_nokogiri.root.name == 'CreditNote'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-CreditNote_2.1.sch)
        else
          %w(CEN-EN16931-UBL.sch EN16931-CII-validation.sch)
        end

      # XRechnung UBL 2.2
      when 'urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_2.2'
        if doc_nokogiri.root.name == 'Invoice'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-Invoice_2.2.sch)
        elsif doc_nokogiri.root.name == 'CreditNote'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-CreditNote_2.2.sch)
        else
          %w(CEN-EN16931-UBL.sch EN16931-CII-validation.sch)
        end

      # XRechnung UBL 3.0
      when 'urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0'
        if %w(Invoice CreditNote).include?(doc_nokogiri.root.name)
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation_3.0.sch)
        else
          %w(CEN-EN16931-UBL.sch EN16931-CII-validation.sch)
        end

      # NL CIUS / SimplerInvoicing
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:nen.nl:nlcius:v1.0'
        %w(si-ubl-2.0.sch)

      # PEPPOL Order Response transaction 3.0
      when 'urn:fdc:peppol.eu:poacc:trns:order_response:3'
        %w(PEPPOLBIS-T76.sch)

      # CIUS-PT portugal
      when 'urn:cen.eu:en16931:2017#compliant#urn:feap.gov.pt:CIUS-PT::v1.0'
        %w(urn_feap.gov.pt_CIUS-PT_2.1.2.sch)

      # Andorra
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:andorra'
        %w(CEN-EN16931-UBL.sch)

      else
        profile_id = doc_nokogiri.xpath('//cbc:ProfileID', cbc: CBC).text

        if profile_id == 'reporting:1.0'
          # we dont have the sch, only the compiled files
          %w(ZATCA_E-invoice_20210819 CEN-EN16931-UBL-ZATCA)
        else
          raise StandardError.new("Unknown CustomizationID '#{customization_id}' and ProfileID '#{profile_id}'")
        end
      end
    end

    # Creates compiled xslt
    def self.compile
      Dir.chdir('lib/sch/schemas/') do
        Dir["*.sch","*/*.sch","xrechnung/*/*/*.sch"].each do |schematron_file|
          cache_xslt = "../compiled/#{File.basename(schematron_file)}.xslt"
          compiled_schematron = schematron_compile(schematron_file)
          File.write(cache_xslt, compiled_schematron)
        end
      end
    end

    # schematron-wrapper patch ################
    def self.schematron_compile(file_path)
      # process_includes does not work in /tmp. it needs access to included files
      temp_schematron = Schematron::XSLT2.execute_transform(Schematron::XSLT2::DSDL_INCLUDES_PATH, file_path)
      temp_schematron = Schematron::XSLT2.expand_abstract_patterns(temp_schematron)
      Schematron::XSLT2.create_stylesheet(temp_schematron)
    end

    private

    def xslt_path(name)
      File.expand_path("../compiled/#{name}.xslt", __FILE__)
    end
  end
end
