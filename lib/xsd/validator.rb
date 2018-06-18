require "xsd/validator/version"
require 'nokogiri'

module Xsd
  module Validator
    SII_LR = "https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroLR.xsd"
    SII_INFORMACION = "https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroInformacion.xsd"
    GIPUZKOA_SII_LR = "https://egoitza.gipuzkoa.eus/ogasuna/sii/ficheros/SuministroLR.xsd"
    BIZKAIA_SII_LR = "http://www.bizkaia.eus/ogasuna/sii/documentos/SuministroLR.xsd"

    class ValidationError < RuntimeError
    end

    def xsd_validate(doc)
      doc=Nokogiri::XML(doc) unless doc.is_a? Nokogiri::XML::Document
      xsd_path=root_namespace_xsd(doc)
      xsd = File.read(xsd_path)
      errors = nil
      # El chdir és perquè el xsd agafi el schemaLocation
      Dir.chdir(File.dirname(xsd_path)) do
        xsd = Nokogiri::XML::Schema(xsd)
        errors = xsd.validate(doc)
      end
      errors
    end

    def xsd_validate!(doc)
      errors = xsd_validate(doc)
      raise ValidationError.new(errors.join("\n")) if errors.any?
      return true
    end

    def root_namespace(doc)
      doc=Nokogiri::XML(doc) unless doc.is_a? Nokogiri::XML::Document
      if doc.root.nil?
        raise StandardError.new("Is not a valid XML")
      elsif doc.root.namespace.nil?
        raise StandardError.new("XML does not have a root namespace")
      else
        doc.root.namespace.href
      end
    end

    def root_namespace_xsd(doc)
      doc=Nokogiri::XML(doc) unless doc.is_a? Nokogiri::XML::Document
      namespace = root_namespace(doc)
      case namespace
      when "http://www.facturae.gob.es/formato/Versiones/Facturaev3_2_2.xml"
        schema_path('facturae322.xsd')
      when "http://www.peppol.eu/schema/pd/businesscard/20160112/"
        schema_path('peppol-directory-business-card-20160112.xsd')
      when "http://www.facturae.es/Facturae/2014/v3.2.1/Facturae"
        schema_path('facturae321.xsd')
      when "http://www.facturae.es/Facturae/2009/v3.2/Facturae"
        schema_path('facturae32.xsd')
      when "http://www.facturae.es/Facturae/2007/v3.1/Facturae"
        schema_path('facturae31.xsd')
      when "http://www.facturae.es/Facturae/2007/v3.0/Facturae"
        schema_path('facturae30.xsd')
      when SII_LR
        case doc.xpath('//sii:Cabecera/sii:IDVersionSii', sii: SII_INFORMACION).text
        when '1.0'
          schema_path('sii_v10/SuministroLR.xsd')
        when '0.7'
          schema_path('sii_v07/SuministroLR.xsd')
        else
          schema_path('sii_v06/SuministroLR.xsd')
        end
      when GIPUZKOA_SII_LR
        schema_path('sii_gipuzkoa/SuministroLR.xsd')
      when BIZKAIA_SII_LR
        schema_path('sii_bizkaia/SuministroLR.xsd')
      else
        raise StandardError.new("Unknown namespace #{namespace}")
      end
    end

    private

    def schema_path(xsdname)
      File.expand_path("../schemas/#{xsdname}", __FILE__)
    end
  end
end
