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
end
