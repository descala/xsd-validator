RSpec.describe 'Schematron::XSLT2' do

  context '#execute_transform' do
    files = {
      'spec/files/sch/factur-x/factur-x-minimum.xml' => 'FACTUR-X_MINIMUM.sch.xslt',
      'spec/files/sch/factur-x/factur-x-basic.xml' => 'EN16931-CII-validation-preprocessed.sch.xslt',
      'spec/files/sch/factur-x/factur-x-basic-wl.xml' => 'FACTUR-X_BASIC-WL.sch.xslt',
      'spec/files/sch/factur-x/factur-x-extended.xml' => 'FACTUR-X_EXTENDED.sch.xslt'
    }
    files.each do |file_path, xslt|
      it "#{file_path} check validation_result format" do
        doc = File.read(file_path)
        compiled_schematron = File.read(File.expand_path("lib/sch/compiled/#{xslt}"))
        validation_result = Schematron::XSLT2.validate(compiled_schematron, doc)
        expect(validation_result).to match(/<\/svrl:schematron-output>/)
      end

    end
  end
end
