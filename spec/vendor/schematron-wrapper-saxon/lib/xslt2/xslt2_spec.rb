RSpec.describe 'Schematron::XSLT2' do

  context '#execute_transform' do
    files = {
      'spec/files/sch/factur-x/factur-x-minimum.xml' => 'FACTUR-X_MINIMUM_V1.0.sch.xslt',
      'spec/files/sch/factur-x/factur-x-basic.xml' => 'EN16931-CII-validation-preprocessed.sch.xslt',
      'spec/files/sch/factur-x/factur-x-basic-wl.xml' => 'FACTUR-X_BASIC-WL_V1.09.2.sch.xslt',
      'spec/files/sch/factur-x/factur-x-extended.xml' => 'FACTUR-X_EXTENDED_V1.09.2.sch.xslt'
    }
    files.each do |file_path, xslt|
      # validate_stylesheet, not validate: the Factur-X stylesheets resolve their code lists against
      # their own directory, so handing saxon a copy in /tmp aborts the transform part-way and the
      # result never reaches its closing tag.
      it "#{file_path} check validation_result format" do
        doc = File.read(file_path)
        validation_result = Schematron::XSLT2.validate_stylesheet(File.expand_path("lib/sch/compiled/#{xslt}"), doc)
        expect(validation_result).to match(/<\/svrl:schematron-output>/)
      end

    end
  end
end
