RSpec.describe Xsd::Validator do

  include Xsd::Validator

  it "has a version number" do
    expect(Xsd::Validator::VERSION).not_to be nil
  end

  it 'knows the root namespace' do
    doc = "<thing xmlns='asdf'>asdf</thing>"
    expect(root_namespace(doc)).to eq('asdf')
    doc = "<ns:thing xmlns:ns='asdf'>asdf</thing>"
    expect(root_namespace(doc)).to eq('asdf')
    doc = "junk"
    expect { root_namespace(doc) }.to raise_error "Is not a valid XML"
    doc = "<thing>asdf</thing>"
    expect { root_namespace(doc) }.to raise_error "XML does not have a root namespace"
  end

  it 'raises error' do
    doc="<facturae:Facturae xmlns:facturae=\"http://www.facturae.es/Facturae/2009/v3.2/Facturae\"></facurae>"
    expect { xsd_validate!(doc) }.to raise_error(/Missing child element/)
  end

  it 'raises error if namespace is unknown' do
    doc = "<ns:thing xmlns:ns='asdf'>asdf</thing>"
    expect { xsd_validate!(doc) }.to raise_error "Unknown namespace asdf"
  end

  it 'raises ValidationError for an invalid XML' do
    doc=File.read('spec/files/xsd/facturae321_wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError)
  end

  it 'validates spec files' do
    Dir["spec/files/xsd/**/*.xml"].each do |filename|
      next if filename =~ /wrong/
      doc=File.read(filename) rescue next
      expect(xsd_validate(doc)).to eq([]), "Error validating fixture #{filename}"
    end
  end

  context 'check choose correct validator xsd path' do
    files = {
      'spec/files/xsd/factur-x/factur-x-minimum.xml' => /FACTUR-X_MINIMUM.xsd/,
      'spec/files/xsd/factur-x/factur-x-basic.xml' => /FACTUR-X_BASIC.xsd/,
      'spec/files/xsd/factur-x/factur-x-basic-wl.xml' => /FACTUR-X_BASIC-WL.xsd/,
      'spec/files/xsd/factur-x/factur-x-en16931.xml' => /FACTUR-X_EN16931.xsd/,
      'spec/files/xsd/factur-x/factur-x-extended.xml' => /FACTUR-X_EXTENDED.xsd/,
      'spec/files/xsd/cii/zugferd_1.xml' => /FACTUR-X_EN16931.xsd/,
      'spec/files/sch/cii/xrechnung-cii_3.0-wrong.xml' => 'FACTUR-X_EN16931.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.3-wrong.xml' => 'FACTUR-X_EN16931.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.2-wrong.xml' => 'FACTUR-X_EN16931.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.1.xml' => 'FACTUR-X_EN16931.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.0.xml' => 'FACTUR-X_EN16931.xsd',
    }
    files.each do |file_path, rgex_xsd_path|
      it "#{file_path} checks with #{rgex_xsd_path}" do
        expect(root_namespace_xsd(File.read(file_path))).to match(rgex_xsd_path)
      end
    end
  end
end
