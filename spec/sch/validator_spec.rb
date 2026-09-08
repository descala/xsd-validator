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

  # EXTENDED-CTC-FR-UBL.sch (#89461 F6) not in sweep; needs explicit zero-error check (CII covered).
  it 'validates the UBL EXTENDED-CTC-FR fixtures clean with the FNFE profile schematron' do
    ['spec/files/xsd/ubl-invoice-fr-extended-ctc-dot.xml',
     'spec/files/xsd/ubl-invoice-fr-extended-ctc-colon.xml'].each do |filename|
      result = sch_validate(File.read(filename))
      expect(result).to eq([[], []]), "Error validating fixture #{filename}: #{result}"
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

  it 'raises ValidationError in for SE-R-003' do
    doc=File.read('spec/files/sch/invoice-se-wrong-identifier.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*SE-R-003/)
  end

  it 'raises ValidationError for an invalid JP Standard Invoice' do
    doc=File.read('spec/files/sch/jp-pint-invoice-ubl-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*aligned-ibrp-cl-01-jp/)
  end

  it 'raises ValidationError for an invalid JP NTR Invoice' do
    doc=File.read('spec/files/sch/jp-pint-ntr-invoice-ubl-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*aligned-ibr-jp-04-ntr/)
  end

  it 'raises ValidationError for an invalid ZATCA Invoice' do
    doc=File.read('spec/files/sch/zatca-ubl-tax-invoice-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /ERROR: .*BR-KSA-40/)
  end

  it 'raises ValidationError for an invalid SK TDD (TaxDataTypeCode not in code list)' do
    doc=File.read('spec/files/sch/sk-tdd-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*ibr-tdd-06/)
  end

  # V1.4.0 turns the whole BR-FR Flux 2 rule set fatal; under V1.3.1 this same document
  # produced a warning only, so we passed invoices that receivers went on to reject (#89917).
  it 'raises ValidationError for a CIUS-FR UBL invoice repeating a BT-21 note subject code' do
    doc=File.read('spec/files/sch/invoice-ubl-cius-fr-notes-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*BR-FR-06\/BT-21/)
  end

  # G1.24 admits French rates only, no exception for foreign suppliers.
  it 'raises ValidationError for an F10 report carrying a non-French VAT rate' do
    doc=File.read('spec/files/sch/f10/f10-report-bi2b-foreign-rate-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*G1\.24/)
  end

  it 'raises ValidationError for an F10 report with an unknown transmission type' do
    doc=File.read('spec/files/sch/f10/f10-report-transactions-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*G8\.01/)
  end

  it 'raises ValidationError for an F1 extract identifying a party without SIREN' do
    doc=File.read('spec/files/sch/f1/f1-extract-scheme-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*G1\.63/)
  end

  it 'raises ValidationError for an F1 extract with a rate outside the French legal list' do
    doc=File.read('spec/files/sch/f1/f1-extract-vat-rate-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*G1\.24/)
  end

  it 'raises ValidationError for an F1 extract with an exempt breakdown missing its code' do
    doc=File.read('spec/files/sch/f1/f1-extract-exempt-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*G1\.41/)
  end

  it 'does not raise for a valid AE PINT Invoice' do
    doc=File.read('spec/files/sch/PINT_AE_invoice.xml')
    expect { sch_validate!(doc) }.not_to raise_error
  end

  it 'raises ValidationError for an AE PINT Invoice missing UUID' do
    doc=File.read('spec/files/sch/PINT_AE_invoice-wrong.xml')
    expect { sch_validate!(doc) }.to raise_error(Sch::Validator::ValidationError, /FATAL: .*ibr-193-ae/)
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
      # Factur-X France (#72838): a French BT-23 process code adds BR-FR to the
      # mandatory-set profiles; BASIC, outside that set, keeps only its own schematron.
      'spec/files/sch/factur-x/factur-x-fr-en16931.xml' =>
        ['EN16931-CII-validation-preprocessed.sch', 'BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch'],
      'spec/files/sch/factur-x/factur-x-fr-extended.xml' =>
        ['FACTUR-X_EXTENDED.sch', 'BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch'],
      'spec/files/sch/factur-x/factur-x-fr-basic-wl.xml' =>
        ['FACTUR-X_BASIC-WL.sch', 'BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch'],
      'spec/files/sch/factur-x/factur-x-fr-basic.xml' => ['EN16931-CII-validation-preprocessed.sch'],
      'spec/files/sch/factur-x/factur-x-fr-extended-ctc-dot.xml' =>
        ['EXTENDED-CTC-FR-CII.sch', 'BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch'],
      'spec/files/sch/factur-x/factur-x-fr-extended-ctc-colon.xml' =>
        ['EXTENDED-CTC-FR-CII.sch', 'BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch'],
      'spec/files/sch/cii/xrechnung-cii_3.0-wrong.xml' => ['EN16931-CII-validation.sch', 'XRechnung-CII-validation_3.0.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.3-wrong.xml' => ['EN16931-CII-validation.sch', 'XRechnung-CII-validation_2.3.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.2.xml' => ['EN16931-CII-validation.sch', 'XRechnung-CII-validation_2.2.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.1.xml' => ['EN16931-CII-validation.sch', 'XRechnung-CII-validation_2.1.sch'],
      'spec/files/sch/cii/xrechnung-cii_2.0.xml' => ['EN16931-CII-validation.sch', 'XRechnung-CII-validation_2.0.sch'],
      'spec/files/sch/xrechnung-ubl_3.0-credit-note.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_3.0.sch'],
      'spec/files/sch/xrechnung-ubl_3.0.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_3.0.sch'],
      'spec/files/sch/xrechnung-ubl_2.3.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_2.3.sch'],
      'spec/files/sch/xrechnung-ubl_2.3-credit-note.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation_2.3.sch'],
      'spec/files/sch/xrechnung-ubl_2.2.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation-Invoice_2.2.sch'],
      'spec/files/sch/xrechnung-ubl_2.2-credit-note.xml' => ['CEN-EN16931-UBL.sch','XRechnung-UBL-validation-CreditNote_2.2.sch'],
      'spec/files/xsd/peppol-selfbilling-base.xml' => ['CEN-EN16931-UBL.sch', 'PEPPOL-EN16931-UBL-SB.sch'],
      'spec/files/xsd/peppol-selfbilling-creditnote.xml' => ['CEN-EN16931-UBL.sch', 'PEPPOL-EN16931-UBL-SB.sch'],
      'spec/files/sch/invoice-se-wrong-identifier.xml' => ['CEN-EN16931-UBL.sch', 'PEPPOL-EN16931-UBL.sch'],
      'spec/files/sch/invoice-ubl-cius-fr.xml' => ['BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch'],
      'spec/files/sch/invoice-cii-cius-fr.xml' => ['BR-FR-Flux2-Schematron-CII_V1.4.0.04.sch'],
      # Bare EN16931 / extended-ctc-fr BT-24 reaching a UBL root (#89461's
      # UblFrProfileDetection is the first code path that makes this happen from
      # real UBL) must resolve UBL schematrons, not silently fall back to CII ones.
      'spec/files/xsd/ubl-invoice-fr-en16931.xml' => ['CEN-EN16931-UBL.sch', 'BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch'],
      'spec/files/xsd/ubl-invoice-fr-en16931-generic.xml' => ['CEN-EN16931-UBL.sch'],
      'spec/files/xsd/ubl-invoice-fr-extended-ctc-dot.xml' =>
        ['EXTENDED-CTC-FR-UBL.sch', 'BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch'],
      'spec/files/xsd/ubl-invoice-fr-extended-ctc-colon.xml' =>
        ['EXTENDED-CTC-FR-UBL.sch', 'BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch'],
      # Pre-existing gap: the Peppol-URN CIUS/Extended branch only checked
      # root.name == 'Invoice', so a CreditNote fell through to the CII file.
      'spec/files/xsd/ubl-credit-note-fr-cius.xml' => ['BR-FR-Flux2-Schematron-UBL_V1.4.0.04.sch'],
      'spec/files/sch/cdar/cdar_1_deposee.xml' => ['BR-FR-CDV-Schematron-CDAR_V1.4.0.03.sch'],
      'spec/files/sch/f10/f10-report-transactions.xml' => ['BR-FR-Flux10-Schematron_V1.0.sch'],
      'spec/files/sch/f10/f10-report-payments.xml' => ['BR-FR-Flux10-Schematron_V1.0.sch'],
      'spec/files/sch/f10/f10-report-bi2b-foreign-rate-wrong.xml' => ['BR-FR-Flux10-Schematron_V1.0.sch'],
      'spec/files/sch/f1/f1-extract-invoice.xml' => ['PPF_Flux1_UBL_1_8_DEMARRAGE_v0_2.sch'],
      'spec/files/sch/f1/f1-extract-creditnote.xml' => ['PPF_Flux1_UBL_1_8_DEMARRAGE_v0_2.sch'],
      # Non-EUR F1 resolves too — the patched G1.53 validates it instead of crashing.
      'spec/files/f1/f1-extract-foreign-currency.xml' => ['PPF_Flux1_UBL_1_8_DEMARRAGE_v0_2.sch'],
      'spec/files/sch/PINT_AE_invoice.xml' => ['PINT-billing-1-shared.sch', 'PINT-AE-billing-1-aligned.sch'],
      'spec/files/sch/sk-tdd.xml' => ['Peppol-Slovak-Republic-TDD.sch'],
      'spec/files/sch/SG_order_balance.xml' => ['SGBIS-TOB.sch'],
    }
    files.each do |file_path, schematrons|
      it "#{file_path} checks with #{schematrons}" do
        expect(schematrons(File.read(file_path), nil)).to eq(schematrons)
      end
    end
  end
end
