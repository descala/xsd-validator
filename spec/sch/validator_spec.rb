require 'sch/validator'

RSpec.describe Sch::Validator do

  include Sch::Validator

  it 'validates spec files' do
    Dir["spec/files/sch/**/*"].each do |filename|
      next if filename =~ /wrong/
      doc=File.read(filename) rescue next
      expect(sch_validate(doc)).to eq([]), "Error validating fixture #{filename}"
    end
  end

  it 'raises ValidationError for an invalid XML' do
    doc=File.read('spec/files/sch/invoice-se-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError)
  end

end
