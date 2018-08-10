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

  it 'validates facture32' do
    doc=File.read('spec/files/13506.facturae32.xml')
    expect(root_namespace_xsd(doc)).to match(/xsd-validator\/lib\/xsd\/schemas\/facturae32.xsd/)
    expect(xsd_validate!(doc)).to eq(true)
    doc="<facturae:Facturae xmlns:facturae=\"http://www.facturae.es/Facturae/2009/v3.2/Facturae\"></facurae>"
    expect { xsd_validate!(doc) }.to raise_error(/Missing child element/)
  end

  it 'validates facture321' do
    doc=File.read('spec/files/facturae321.xml')
    expect(xsd_validate!(doc)).to eq(true)
  end

  it 'validates signed facture32' do
    doc=File.read('spec/files/47610.facturae32.jccm.xsig')
    expect(xsd_validate!(doc)).to eq(true)
  end

  it 'validates facturae32 with Extensions' do
    doc=File.read('spec/files/facturae32_with_extension.xml')
    expect(xsd_validate!(doc)).to eq(true)
  end

  it 'validates signed facture31' do
    doc=File.read('spec/files/facturae31.xml')
    expect(xsd_validate!(doc)).to eq(true)
  end

  it 'validates signed facture30' do
    doc=File.read('spec/files/facturae30.xml')
    expect(xsd_validate!(doc)).to eq(true)
  end

  describe 'validates facturae322 with face b2b extension' do
    it 'version 1.0' do
      doc=File.read('spec/files/facturae322.xml')
      expect(xsd_validate!(doc)).to eq(true)
    end

    it 'version 1.1' do
      doc=File.read('spec/files/facturae322_fb2b11.xml')
      expect(xsd_validate!(doc)).to eq(true)
    end
  end

  it 'validates SII documents' do
    doc=File.read('spec/files/sii/sii-factura-emitida-v06.xml')
    expect(xsd_validate!(doc)).to eq(true)
    doc=File.read('spec/files/sii/sii-factura-emitida1.xml')
    expect(xsd_validate!(doc)).to eq(true)
    doc=File.read('spec/files/sii/sii-factura-bizkaia.xml')
    expect(xsd_validate!(doc)).to eq(true)
    doc=File.read('spec/files/sii/sii-factura-gipuzkoa.xml')
    expect(xsd_validate!(doc)).to eq(true)
  end

  it 'raises error if namespace is unknown' do
    doc = "<ns:thing xmlns:ns='asdf'>asdf</thing>"
    expect { xsd_validate!(doc) }.to raise_error "Unknown namespace asdf"
  end

  it 'raises ValidationError for an invalid XML' do
    doc=File.read('spec/files/facturae321_wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError)
  end

  it 'validates facture32 with signature and xades extensions' do
    doc=File.read('spec/files/xades.xml')
    expect(xsd_validate!(doc)).to eq(true)
  end

end
