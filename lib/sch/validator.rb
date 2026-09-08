require 'nokogiri'
require_relative '../../vendor/schematron-wrapper-saxon/lib/schematron'

module Sch
  module Validator

    CBC = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
    CAC = "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
    RAM = "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"
    RSM = "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100"

    class ValidationError < RuntimeError
    end

    class ValidationWarning < RuntimeError
    end

    class ResultHandler
      def initialize(validation_result)
        @document = Nokogiri::XML(validation_result) do |config|
          config.options = Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::NOENT
          config.huge
        end
      end

      def errors
        build_result('fatal') + build_result('error')
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

    # - parts: how many parts of the wildcard should be validated (PINT)
    #    0 - only shared
    #    1..n - for each @
    def sch_validate(doc, parts = nil)
      errors = []
      warnings = []
      schematrons(doc, parts).each do |schematron_file|
        compiled_schematron = File.read(xslt_path(schematron_file))
        validation_result = Schematron::XSLT2.validate(compiled_schematron, doc)
        result_handler = ResultHandler.new(validation_result)
        errors += result_handler.errors
        warnings = warnings + result_handler.warnings
      end
      return errors, warnings
    end

    def sch_validate!(doc, parts = nil)
      errors, warnings = sch_validate(doc, parts)
      raise ValidationError.new((errors+warnings).join("\n")) if errors.any?
      raise ValidationWarning.new(warnings.join("\n")) if warnings.any?
      return true
    end

    def sch_validate_with_schematron_linked(doc, parts = nil, schematrons = nil)
      errors = []
      warnings = []
      schematrons ||= schematrons(doc, parts)
      schematrons.each do |schematron_file|
        compiled_schematron = File.read(xslt_path(schematron_file))
        validation_result = Schematron::XSLT2.validate(compiled_schematron, doc)
        result_handler = ResultHandler.new(validation_result)
        result_handler.errors.each do |error|
          errors << [schematron_file, error]
        end
        result_handler.warnings.each do |warning|
          warnings << [schematron_file, warning]
        end
      end
      [errors, warnings]
    end

    def schematrons(doc, parts)
      if doc.is_a? Nokogiri::XML::Document
        doc_nokogiri = doc
      else
        doc_nokogiri = Nokogiri::XML(doc) { |c| c.huge }
      end
      # F10 e-reporting carries no CustomizationID; keyed on the Report root instead.
      if doc_nokogiri.root&.name == 'Report' && doc_nokogiri.root.at_xpath('ReportDocument')
        return %w(BR-FR-Flux10-Schematron_V1.0.sch)
      end

      # Assume UBL or CII
      # Read the document-level CustomizationID (direct child of the root element). Using the
      # descendant axis (//) would also match a CustomizationID inside an embedded document - e.g.
      # the UBL invoice carried in a SK TDD's pxs:ReportedDocument - and .text would concatenate
      # both into a string that matches no branch.
      customization_id = doc_nokogiri.xpath('/*/cbc:CustomizationID', cbc: CBC).text
      if customization_id.empty?
        customization_id = doc_nokogiri.xpath('//ram:GuidelineSpecifiedDocumentContextParameter/ram:ID', ram: RAM).text
      end
      if customization_id.empty?
        customization_id = doc_nokogiri.xpath('//xmlns:CustomizationID').text
      end
      case customization_id
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0'
        %w(CEN-EN16931-UBL.sch PEPPOL-EN16931-UBL.sch)
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:selfbilling:3.0'
        %w(CEN-EN16931-UBL.sch PEPPOL-EN16931-UBL-SB.sch)
      when 'urn:cen.eu:en16931:2017#conformant#urn:fdc:peppol.eu:2017:poacc:billing:international:aunz:3.0'
        %w(AUNZ-UBL-validation.sch AUNZ-PEPPOL-validation.sch)
      when 'urn:cen.eu:en16931:2017#conformant#urn:fdc:peppol.eu:2017:poacc:selfbilling:international:aunz:3.0'
        %w(AUNZ-UBL-validation.sch AUNZ-PEPPOL-SB-validation.sch)
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
      when /^urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_2.0/,
          /^urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_2.0/
        if doc_nokogiri.root.name == 'Invoice'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-Invoice_2.0.sch)
        elsif doc_nokogiri.root.name == 'CreditNote'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-CreditNote_2.0.sch)
        else # CII
          %w(EN16931-CII-validation.sch XRechnung-CII-validation_2.0.sch)
        end

      # XRechnung UBL 2.1
      when /^urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_2.1/,
           /^urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_2.1/
        if doc_nokogiri.root.name == 'Invoice'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-Invoice_2.1.sch)
        elsif doc_nokogiri.root.name == 'CreditNote'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-CreditNote_2.1.sch)
        else
          %w(EN16931-CII-validation.sch XRechnung-CII-validation_2.1.sch)
        end

      # XRechnung UBL 2.2
      when /^urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_2.2/,
           /^urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_2.2/
        if doc_nokogiri.root.name == 'Invoice'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-Invoice_2.2.sch)
        elsif doc_nokogiri.root.name == 'CreditNote'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation-CreditNote_2.2.sch)
        else
          %w(EN16931-CII-validation.sch XRechnung-CII-validation_2.2.sch)
        end

        # XRechnung UBL 2.3
      when /^urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_2.3/,
           /^urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_2.3/
        if doc_nokogiri.root.name == 'Invoice' || doc_nokogiri.root.name == 'CreditNote'
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation_2.3.sch)
        else #'CrossIndustryInvoice'
          %w(EN16931-CII-validation.sch XRechnung-CII-validation_2.3.sch)
        end

      # XRechnung UBL 3.0
      when /^urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_3.0/,
           /^urn:cen.eu:en16931:2017#compliant#urn:xeinkauf.de:kosit:xrechnung_3.0/
        if %w(Invoice CreditNote).include?(doc_nokogiri.root.name)
          %w(CEN-EN16931-UBL.sch XRechnung-UBL-validation_3.0.sch)
        else #'CrossIndustryInvoice'
          %w(EN16931-CII-validation.sch XRechnung-CII-validation_3.0.sch)
        end

      # Factur-X Profil MINIMUM
      when 'urn:factur-x.eu:1p0:minimum'
        %w(FACTUR-X_MINIMUM.sch)

      # Factur-X Profil BASIC WL
      when 'urn:factur-x.eu:1p0:basicwl'
        add_br_fr_schematron_if_french(%w(FACTUR-X_BASIC-WL.sch), doc_nokogiri)

      # Factur-X Profil BASIC (outside the mandatory French set: never BR-FR)
      when 'urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic'
        %w(EN16931-CII-validation-preprocessed.sch)

      # Factur-X Profil EN 16931 (COMFORT) (mandatory French set) — same bare URN
      # is also the UBL France CIUS BT-24 (#89461's UblFrProfileDetection), so
      # root-awareness matters here, unlike most other branches in this case.
      when 'urn:cen.eu:en16931:2017'
        if %w(Invoice CreditNote).include?(doc_nokogiri.root.name)
          add_br_fr_schematron_if_french_ubl(%w(CEN-EN16931-UBL.sch), doc_nokogiri)
        else
          add_br_fr_schematron_if_french(%w(EN16931-CII-validation-preprocessed.sch), doc_nokogiri)
        end

      # Factur-X Profil EXTENDED (mandatory French set)
      when 'urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:extended'
        add_br_fr_schematron_if_french(%w(FACTUR-X_EXTENDED.sch), doc_nokogiri)

      # Factur-X EXTENDED-CTC-FR (FNFE V1.4.0.04, applicable from 2026-10-01;
      # AFNOR examples use the dot form, the XP Z12-012 text the colon form) — also
      # reachable from UBL (#89461's UblFrProfileDetection); already unambiguously
      # French, no BT-23 guard needed unlike the bare-EN16931 branch above.
      when 'urn:cen.eu:en16931:2017#conformant#urn.cpro.gouv.fr:1p0:extended-ctc-fr',
           'urn:cen.eu:en16931:2017#conformant#urn:cpro.gouv.fr:1p0:extended-ctc-fr'
        if %w(Invoice CreditNote).include?(doc_nokogiri.root.name)
          %w(EXTENDED-CTC-FR-UBL.sch BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch)
        else
          %w(EXTENDED-CTC-FR-CII.sch BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch)
        end

      # NL CIUS / SimplerInvoicing
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:nen.nl:nlcius:v1.0'
        %w(si-ubl-2.0.sch)

      # PEPPOL Order transaction
      when 'urn:fdc:peppol.eu:poacc:trns:order:3'
        %w(PEPPOLBIS-T01.sch)

      # PEPPOL Order Response transaction 3.0
      when 'urn:fdc:peppol.eu:poacc:trns:order_response:3'
        %w(PEPPOLBIS-T76.sch)

      # PEPPOL Order Agreement transaction 3.1
      when 'urn:fdc:peppol.eu:poacc:trns:order_agreement:3'
        %w(PEPPOLBIS-T110.sch)

      # PEPPOL Order Change transaction 3.0
      when 'urn:fdc:peppol.eu:poacc:trns:order_change:3'
        %w(PEPPOLBIS-T114.sch)

      # PEPPOL Order Cancellation transaction 3.0
      when 'urn:fdc:peppol.eu:poacc:trns:order_cancellation:3'
        %w(PEPPOLBIS-T115.sch)

      # PEPPOL Order Response Advanced transaction 3.0
      when 'urn:fdc:peppol.eu:poacc:trns:order_response_advanced:3'
        %w(PEPPOLBIS-T116.sch)

      # SG BIS Order balance 1
      when 'urn:fdc:imda.gov.sg:trns:order_balance:1'
        %w(SGBIS-TOB.sch)

      # CIUS-PT portugal
      when 'urn:cen.eu:en16931:2017#compliant#urn:feap.gov.pt:CIUS-PT::v1.0'
        %w(urn_feap.gov.pt_CIUS-PT_2.1.2.sch)

      # Andorra
      when 'urn:cen.eu:en16931:2017#compliant#urn:fdc:andorra'
        %w(CEN-EN16931-UBL.sch)

      # JP PINT Invoice v1.0
      when 'urn:peppol:pint:billing-1@jp-1'
        schemas = %w(PINT-billing-1-shared.sch PINT-JP-billing-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)

      # JP BIS Invoice for Non-tax Registered Businesses
      when 'urn:peppol:pint:nontaxinvoice-1@jp-1'
        schemas = %w(PINT-JP-nontaxinvoice-1-shared.sch PINT-JP-nontaxinvoice-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)

      # JP BIS Self-Billing Invoice
      when 'urn:peppol:pint:selfbilling-1@jp-1'
        schemas = %w(PINT-JP-selfbilling-1-shared.sch PINT-JP-selfbilling-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)

      # Statistics Reporting End Users
      when 'urn:fdc:peppol.eu:edec:trns:end-user-statistics-report:1.1'
        %w(peppol-end-user-statistics-reporting-1.1.4.sch)

      # Statistics Reporting Transactions
      when 'urn:fdc:peppol.eu:edec:trns:transaction-statistics-reporting:1.0'
        %w(peppol-transaction-statistics-reporting-1.0.4.sch)

      # Catalogue
      when 'urn:fdc:peppol.eu:poacc:trns:catalogue:3'
        %w(PEPPOLBIS-T19.sch)

      # Catalogue Response
      when 'urn:fdc:peppol.eu:poacc:trns:catalogue_response:3'
        %w(PEPPOLBIS-T58.sch)

      # Punch Out transaction 3.2
      when 'urn:fdc:peppol.eu:poacc:trns:punch_out:3'
        %w(PEPPOLBIS-T77.sch)

      # A-NZ PINT Invoice v1.0, A-NZ PINT CreditNote v1.0
      when 'urn:peppol:pint:billing-1@aunz-1'
        schemas = %w(PINT-billing-1-shared.sch PINT-AUNZ-billing-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)

      # A-NZ PINT Self-Billing Invoice v1.0, A-NZ PINT Self-Billing CreditNote v1.0
      when 'urn:peppol:pint:selfbilling-1@aunz-1'
        schemas = %w(PINT-AUNZ-selfbilling-1-shared.sch PINT-AUNZ-selfbilling-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)

      # SG PINT Invoice v1.0, SG PINT CreditNote v1.0
      when 'urn:peppol:pint:billing-1@sg-1'
        schemas = %w(PINT-billing-1-shared.sch PINT-SG-billing-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)

      # MY PINT Invoice v1.0
      when 'urn:peppol:pint:billing-1@my-1'
        schemas = %w(PINT-billing-1-shared.sch PINT-MY-billing-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)
      when 'urn:cen.eu:en16931:2017#compliant#urn:peppol:france:billing:cius:1.0',
        'urn:cen.eu:en16931:2017#conformant#urn:peppol:france:billing:extended:1.0'
        if %w(Invoice CreditNote).include?(doc_nokogiri.root.name)
          %w(BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch)
        else
          %w(BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch)
        end
      when 'urn:cen.eu:en16931:2017#conformant#urn:peppol:france:billing:Factur-X:1.0'
        %w(BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch)
        # CDAR CrossDomainAcknowledgementAndResponse
      when ->(v) { v.start_with?('urn.cpro.gouv.fr:1p0:CDV') }
        %w(BR-FR-CDV-Schematron-CDAR_V1.4.0.03.sch)
      # AE PINT Invoice v1.0, AE PINT CreditNote v1.0
      when 'urn:peppol:pint:billing-1@ae-1'
        schemas = %w(PINT-billing-1-shared.sch PINT-AE-billing-1-aligned.sch)
        pint_schemas_to_validate(schemas, parts)

      # SK Tax Data Document (TDD) - pxs:TaxData
      # The EN16931 (CEN/PEPPOL-EN16931-UBL) schematrons validate a UBL Invoice/CreditNote and do
      # not apply to the pxs:TaxData wrapper (confirmed against the OpenPeppol TDD testbed SVRL,
      # which runs only the TDD schematron).
      when 'urn:peppol:taxdata:sk-1'
        %w(Peppol-Slovak-Republic-TDD.sch)

      # PPF Flux 1 e-invoicing extract (Profil de Base) — trajectoire DÉMARRAGE.
      # AIFE delivery v1.0 (Note de conception, 31/07/2026); files keep AIFE's own
      # filenames, whose _v0_2 suffix does not match the delivered version.
      when 'urn.cpro.gouv.fr:1p0:einvoicingextract#Base'
        %w(PPF_Flux1_UBL_1_8_DEMARRAGE_v0_2.sch)
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
        Dir["*.sch","*/*.sch","xrechnung/*/*/*.sch","PINT/*/*.sch"].each do |schematron_file|
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

    # Valid BT-23 process codes ("cadre de facturation") per BR-FR-08 V1.4 — the
    # French character of a Factur-X (ZUGFeRD and Peppol BIS never carry these).
    VALID_FR_PROCESS_CODES = %w(B1 S1 M1 B2 S2 M2 S3 B4 S4 M4 S5 S6 B7 S7 B8 S8 M8 B9 S9 M9)

    # Appends the BR-FR Flux 2 CII schematron when the CII carries a French
    # process code in BT-23 (any repeat counts, BR-FR-08 evaluates all).
    def add_br_fr_schematron_if_french(schematrons, doc_nokogiri)
      bt23_values = doc_nokogiri.xpath('/rsm:CrossIndustryInvoice/rsm:ExchangedDocumentContext/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID',
                                       rsm: RSM, ram: RAM).map { |node| node.text.strip }
      return schematrons if (VALID_FR_PROCESS_CODES & bt23_values).empty?

      schematrons + %w(BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch)
    end

    # UBL sibling of add_br_fr_schematron_if_french: same BT-23 guard, read the
    # UBL way. Mirrors b2b_app's DocumentType::UblFrProfileDetection#french?.
    #
    # Chorus Pro B2G addressing legitimately carries two buyer PartyIdentification
    # elements (SIRET 0009 + code service 0224, BT-46) — valid under BR-FR-Flux2 but
    # fatal under the base CEN rule UBL-SR-16 (max one). Layering BR-FR on top of
    # +schematrons+ can never satisfy that combination, so drop the base instead.
    def add_br_fr_schematron_if_french_ubl(schematrons, doc_nokogiri)
      return schematrons if (VALID_FR_PROCESS_CODES & bt23_values_ubl(doc_nokogiri)).empty?
      return %w(BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch) if buyer_party_identification_count(doc_nokogiri) > 1

      schematrons + %w(BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch)
    end

    # @return [Integer] number of buyer cac:PartyIdentification/cbc:ID elements (BT-46)
    def buyer_party_identification_count(doc_nokogiri)
      doc_nokogiri.xpath('/*/cac:AccountingCustomerParty/cac:Party/cac:PartyIdentification/cbc:ID',
                          cac: CAC, cbc: CBC).size
    end

    # BT-23 ("Cadre de Facturation") from ProfileID (AFNOR) or from an
    # AdditionalDocumentReference tagged CADRE_DE_FACTURATION (Peppol BIS).
    def bt23_values_ubl(doc_nokogiri)
      values = doc_nokogiri.xpath('/*/cbc:ProfileID', cbc: CBC).map { |node| node.text.strip }
      cadre = doc_nokogiri.xpath('//cac:AdditionalDocumentReference', cac: CAC).find do |node|
        node.at_xpath('cbc:DocumentDescription', cbc: CBC)&.text&.strip == 'CADRE_DE_FACTURATION'
      end&.at_xpath('cbc:ID', cbc: CBC)&.text&.strip
      values << cadre if cadre
      values
    end

    def xslt_path(name)
      File.expand_path("../compiled/#{name}.xslt", __FILE__)
    end

    # schemas should be in order of the customization_id wildcard
    # e.g urn:peppol:pint:billing-1@jp-1
    #   billing-1 - PINT-billing-1-shared.sch
    #   @jp-1 - PINT-JP-billing-1-aligned.sch
    #   [PINT-billing-1-shared.sch PINT-JP-billing-1-aligned.sch]
    def pint_schemas_to_validate(schemas, parts)
      # if parts is not given all parts will be validated
      parts ||= schemas.length - 1
      to_validate = []
      schemas.each_with_index do |sch, i|
        if i <= parts
          to_validate << sch
        end
      end
      to_validate
    end
  end
end
