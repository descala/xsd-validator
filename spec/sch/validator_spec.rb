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

  it 'validates wrong spec files' do
    Dir["spec/files/sch/**/*-wrong.xml"].each do |filename|
      doc=File.read(filename) rescue next
      result = sch_validate(doc)
      expect(result).to_not eq([[],[]]), "Didn't found errors in fixture #{filename}: #{result}"
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

  context 'check choose correct schematrons' do
    files = {
      'spec/files/sch/factur-x/factur-x-minimum.xml' => ['FACTUR-X_MINIMUM.sch'],
      'spec/files/sch/factur-x/factur-x-basic.xml' => ['EN16931-CII-validation-preprocessed.sch'],
      'spec/files/sch/factur-x/factur-x-basic-wl.xml' => ['FACTUR-X_BASIC-WL.sch'],
      'spec/files/sch/factur-x/factur-x-en16931.xml' => ['EN16931-CII-validation-preprocessed.sch'],
      'spec/files/sch/factur-x/factur-x-extended.xml' => ['FACTUR-X_EXTENDED.sch'],
      'spec/files/sch/cii/xrechnung-cii_3.0-wrong.xml' => ['XRechnung-CII-validation_3.0.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.3-wrong.xml' => ['XRechnung-CII-validation_2.3.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.2.xml' => ['XRechnung-CII-validation_2.2.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.1.xml' => ['XRechnung-CII-validation_2.1.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.0.xml' => ['XRechnung-CII-validation_2.0.sch'],
      'spec/files/sch/xrechnung-ubl_3.0-credit-note.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_3.0.sch'],
      'spec/files/sch/xrechnung-ubl_3.0.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_3.0.sch'],
      'spec/files/sch/xrechnung-ubl_2.3.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_2.3.sch'],
      'spec/files/sch/xrechnung-ubl_2.3-credit-note.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_2.3.sch'],
      'spec/files/sch/xrechnung-ubl_2.2.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation-Invoice_2.2.sch'],
      'spec/files/sch/xrechnung-ubl_2.2-credit-note.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation-CreditNote_2.2.sch'],
    }
    files.each do |file_path, schematrons|
      it "#{file_path} checks with #{schematrons}" do
        expect(schematrons(File.read(file_path), nil)).to eq(schematrons)
      end
    end
  end

  it 'does not raises ValidationError when languageID' do
    doc=File.read('spec/files/sch/invoice-languageid.xml')
    expect { sch_validate!(doc) }.to_not raise_error(Sch::Validator::ValidationWarning, /WARNING: \[UBL-DT-19\]/)
  end
end
