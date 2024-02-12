require 'sch/validator'

RSpec.describe Sch::Validator do

  include Sch::Validator

  it 'validates spec files' do
    Dir["spec/files/sch/**/*.xml"].each do |filename|
      next if filename =~ /wrong/
      doc=File.read(filename) rescue next
      result = sch_validate(doc)
      expect(result).to eq([[],[]]), "Error validating fixture #{filename}: #{result}"
    end
  end

  it 'raises ValidationError for an invalid CIUS pt' do
    doc=File.read('spec/files/sch/invoice-cius-pt-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*BR-CIUS-PT-18/)
  end

  it 'raises ValidationError for an invalid XML' do
    doc=File.read('spec/files/sch/invoice-se-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*BR-S-08/)
  end

  it 'raises ValidationWarn in no fatal cases' do
    doc=File.read('spec/files/sch/invoice-se-wrong-warn.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationWarning, /WARNING: \[SE-R-003\] Swedish organisation numbers should be numeric/)
  end

  it 'raises ValidationError for an invalid JP Standard Invoice' do
    doc=File.read('spec/files/sch/jp-pint-invoice-ubl-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*aligned-ibrp-cl-01-jp/)
  end

  it 'raises ValidationError for an invalid JP NTR Invoice' do
    doc=File.read('spec/files/sch/jp-pint-ntr-invoice-ubl-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*aligned-ibr-jp-04-ntr/)
  end

  it 'does not raises ValidationError for an invalid JP Standard Invoice with only_shared validation' do
    doc=File.read('spec/files/sch/jp-pint-invoice-ubl-wrong.xml')
    expect { sch_validate!(doc, 0) }.to_not raise_error
  end

end
