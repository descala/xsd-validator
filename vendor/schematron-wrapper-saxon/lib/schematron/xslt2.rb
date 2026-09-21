require 'nokogiri'

module Schematron
  module XSLT2
    extend Schematron::Utils

    ISO_IMPL_DIR = File.join(File.dirname(__FILE__), '../..', 'iso-schematron-xslt2')
    DSDL_INCLUDES_PATH = File.join(ISO_IMPL_DIR, 'iso_dsdl_include.xsl')
    ABSTRACT_EXPAND_PATH = File.join(ISO_IMPL_DIR, 'iso_abstract_expand.xsl')
    SVRL_FOR_XSLT2_PATH = File.join(ISO_IMPL_DIR, 'iso_svrl_for_xslt2.xsl')
    EXE_PATH = File.join(File.dirname(__FILE__), '../..', 'bin/saxon-he-12.5.jar')
    LIB_PATH = File.join(File.dirname(__FILE__), '../../bin/lib/*')

    def self.compile(schematron)
      temp_schematron = process_includes(schematron)
      temp_schematron = expand_abstract_patterns(temp_schematron)

      create_stylesheet(temp_schematron)
    end

    def self.validate(stylesheet, xml)
      create_temp_file(stylesheet) do |temp_stylesheet|
        create_temp_file(xml) do |temp_xml|
          execute_transform(temp_stylesheet.path, temp_xml.path)
        end
      end
    end

    # Validates +xml+ against the compiled stylesheet already on disk at +stylesheet_path+.
    #
    # .validate copies the stylesheet into /tmp, which makes /tmp its base URI. A stylesheet that
    # resolves a sibling resource at run time then silently reads nothing: the Factur-X profiles
    # look their code lists up with document('FACTUR-X_<profile>_codedb.xml'), and saxon returns an
    # empty sequence for the missing file rather than failing. Passing the real path keeps the base
    # URI on the directory that holds those companion files.
    def self.validate_stylesheet(stylesheet_path, xml)
      create_temp_file(xml) { |temp_xml| execute_transform(stylesheet_path, temp_xml.path) }
    end

    def self.get_errors(validation_result)
      result = []

      document = Nokogiri::XML(validation_result) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::NOENT
        config.huge
      end

      document.xpath('//svrl:failed-assert').each do |element|
        result.push({message: element.xpath('./svrl:text').text.strip,
                     role: get_attribute_value(element, '@role'),
                     location: get_attribute_value(element, '@location')})
      end

      result
    end

    private

    def self.process_includes(content_to_transform)
      create_temp_file(content_to_transform) { |temp_file| execute_transform(DSDL_INCLUDES_PATH, temp_file.path) }
    end

    def self.expand_abstract_patterns(content_to_transform)
      create_temp_file(content_to_transform) { |temp_file| execute_transform(ABSTRACT_EXPAND_PATH, temp_file.path) }
    end

    def self.create_stylesheet(content_to_transform)
      create_temp_file(content_to_transform) { |temp_file| execute_transform(SVRL_FOR_XSLT2_PATH, temp_file.path, true) }
    end

    def self.execute_transform(stylesheet, schema, allow_foreign = false)
      sep, null = Gem.win_platform? ? [';', 'nul'] : [':', '/dev/null']

      if ENV['XSD_VALIDATOR_C']
        cmd = "cd #{File.expand_path(File.dirname(__FILE__))}/../../../saxonC_v12.4.2/command && ./transform"
      else
        cmd = "java "

        # https://stackoverflow.com/questions/1491325/how-to-speed-up-java-vm-jvm-startup-time
        # Should run `java -Xshare:dump` on the machine
        cmd << " -XX:TieredStopAtLevel=1"
        cmd << " -XX:CICompilerCount=1"
        cmd << " -XX:+UseSerialGC"
        cmd << " -XX:-UsePerfData"
        cmd << " -Xshare:auto"
        cmd << " -cp #{EXE_PATH + sep + LIB_PATH + sep}. net.sf.saxon.Transform"
      end

      cmd << " -xsl:#{stylesheet}"
      cmd << " -s:#{schema}"

      if allow_foreign
        cmd << ' allow-foreign=true'
      end

      cmd << " 2> #{null}" # Suppress $stderr. Should add verbose param?

      %x{#{cmd}}
    end
  end
end