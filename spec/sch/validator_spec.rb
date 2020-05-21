require 'sch/validator'

RSpec.describe Sch::Validator do

  include Sch::Validator

  it 'validates spec files' do
    Dir["spec/files/sch/**/*"].each do |filename|
      next if filename =~ /wrong/
      doc=File.read(filename) rescue next
      result = sch_validate(doc)
      expect(result).to eq([[],[]]), "Error validating fixture #{filename}: #{result}"
    end
  end

  it 'raises ValidationError for an invalid XML' do
    doc=File.read('spec/files/sch/invoice-se-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*BR-S-08/)
  end

  it 'raises ValidationWarn in no fatal cases' do
    doc=File.read('spec/files/sch/invoice-se-wrong-warn.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationWarning, /WARNING: \[SE-R-003\] Swedish organisation numbers should be numeric/)
  end
end
