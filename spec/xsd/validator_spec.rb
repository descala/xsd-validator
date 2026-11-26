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
    expect(root_namespace(doc)).to be_nil
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

  it 'raises ValidationError for an invalid SK TDD (missing mandatory UUID)' do
    doc=File.read('spec/files/xsd/sk-tdd-wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError, /UUID/)
  end

  it 'raises ValidationError for a Peppol MLS with its elements out of the UBL order' do
    doc=File.read('spec/files/xsd/mls/mls-order-wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError, /IssueTime/)
  end

  it 'rejects an F10 Report carrying the References block removed in PPF v3.1' do
    doc = File.read('spec/files/xsd/dgfip/tax_report_f10/ventes_references_wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError, /References/)
  end

  it 'rejects an F14 Annuaire export without its flow type' do
    doc = File.read('spec/files/xsd/dgfip/annuaire_f14/export_differentiel_wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError, /TypeFlux/)
  end

  it 'raises ValidationError for a DATEV document.xml missing its header' do
    doc=File.read('spec/files/xsd/datev/document_v060_wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError, /header/)
  end

  it 'raises ValidationError for a DATEV LedgerImport with a 0.00 amount' do
    doc=File.read('spec/files/xsd/datev/ledger_import_v060_wrong.xml')
    expect { xsd_validate!(doc) }.to raise_error(Xsd::Validator::ValidationError, /amount/)
  end

  it 'raises UnknownCustomizationIdError for a CII extension (#conformant#) it does not list' do
    doc = File.read('spec/files/xsd/factur-x/factur-x-extended.xml')
      .sub('urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:extended',
           'urn:cen.eu:en16931:2017#conformant#urn:example:unlisted:extended')
    expect { root_namespace_xsd(doc) }
      .to raise_error(Xsd::Validator::UnknownCustomizationIdError, /urn:example:unlisted:extended/)
  end

  it 'routes the #conformant# spelling of Factur-X EN 16931 to the EN 16931 XSD' do
    doc = File.read('spec/files/xsd/factur-x/factur-x-en16931.xml')
      .sub('<ram:ID>urn:cen.eu:en16931:2017</ram:ID>',
           '<ram:ID>urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:en16931</ram:ID>')
    expect(root_namespace_xsd(doc)).to match(%r{factur-x/en16931/FACTUR-X_EN16931\.xsd\z})
  end

  it 'accepts on a CDAR the BR-FR-04 invoice type codes that UNTDID 1001 D22A lacks' do
    cdar = File.read('spec/files/xsd/cdar/cdar_1_deposee.xml')

    %w(471 472 473 500 501 502 503).each do |code|
      doc = cdar.sub('<ram:TypeCode>380</ram:TypeCode>', "<ram:TypeCode>#{code}</ram:TypeCode>")

      expect(xsd_validate(doc)).to eq([]), "MDT-91 #{code} rejected"
    end
  end

  it 'validates spec files' do
    Dir["spec/files/xsd/**/*.xml"].each do |filename|
      next if filename =~ /wrong/
      doc=File.read(filename) rescue next
      expect(xsd_validate(doc)).to eq([]), "Error validating fixture #{filename}"
    end
  end

  # BG-3 (ram:InvoiceReferencedDocument) is 0..n in Factur-X EN16931 and BASIC since they are based on CII D22B. The
  # CII namespace fallback (cii_en16931/, where XRechnung CII 2.x lands) keeps one.
  context 'with two ram:InvoiceReferencedDocument (BG-3)' do
    def with_two_references(filename, guideline_id = nil)
      reference = '<ram:InvoiceReferencedDocument><ram:IssuerAssignedID>F-1</ram:IssuerAssignedID>' \
                  '</ram:InvoiceReferencedDocument>'
      closing = '</ram:SpecifiedTradeSettlementHeaderMonetarySummation>'
      doc = File.read(filename).sub(closing, "#{closing}#{reference * 2}")
      guideline_id ? doc.sub(%r{<ram:ID>urn:cen\.eu:en16931:2017[^<]*</ram:ID>}, "<ram:ID>#{guideline_id}</ram:ID>") : doc
    end

    {
      'spec/files/xsd/factur-x/factur-x-en16931.xml' => 'urn:cen.eu:en16931:2017',
      'spec/files/xsd/factur-x/factur-x-basic.xml' => 'urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic'
    }.each do |filename, guideline_id|
      it "validates #{guideline_id}" do
        expect(xsd_validate(with_two_references(filename))).to eq([])
      end
    end

    it 'validates urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:en16931' do
      doc = with_two_references('spec/files/xsd/factur-x/factur-x-en16931.xml',
                                'urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:en16931')
      expect(xsd_validate(doc)).to eq([])
    end

    it 'refuses the second one on the CII namespace fallback (XRechnung CII 2.1)' do
      filename = 'spec/files/sch/cii/xrechnung-cii_2.1.xml'
      expect(xsd_validate(File.read(filename))).to eq([])
      expect(xsd_validate(with_two_references(filename)).join).to match(/InvoiceReferencedDocument/)
    end
  end

  # BG-16 (ram:SpecifiedTradeSettlementPaymentMeans) is 0..n in Factur-X EN16931 and BASIC 1.09.2: one block per
  # creditor account. The CII namespace fallback (cii_en16931/) and the other Factur-X profiles admit several as well.
  context 'with several ram:SpecifiedTradeSettlementPaymentMeans (BG-16)' do
    def with_two_more_payment_means(filename, guideline_id = nil)
      payment_means = %w[DE91100000000123456789 FR7630006000011234567890189].map do |iban|
        '<ram:SpecifiedTradeSettlementPaymentMeans><ram:TypeCode>58</ram:TypeCode>' \
          "<ram:PayeePartyCreditorFinancialAccount><ram:IBANID>#{iban}</ram:IBANID>" \
          '</ram:PayeePartyCreditorFinancialAccount></ram:SpecifiedTradeSettlementPaymentMeans>'
      end.join
      # The first ram:ApplicableTradeTax of the header settlement: the payment means go right before it.
      doc = File.read(filename).sub(/(<ram:ApplicableHeaderTradeSettlement>.*?)(<ram:ApplicableTradeTax>)/m) do
        "#{Regexp.last_match(1)}#{payment_means}#{Regexp.last_match(2)}"
      end
      guideline_id ? doc.sub(%r{<ram:ID>urn:cen\.eu:en16931:2017[^<]*</ram:ID>}, "<ram:ID>#{guideline_id}</ram:ID>") : doc
    end

    {
      'spec/files/xsd/factur-x/factur-x-en16931.xml' => 'urn:cen.eu:en16931:2017',
      'spec/files/xsd/factur-x/factur-x-basic.xml' => 'urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic'
    }.each do |filename, guideline_id|
      it "validates #{guideline_id}" do
        doc = with_two_more_payment_means(filename)
        expect(doc.scan('<ram:SpecifiedTradeSettlementPaymentMeans>').size).to be >= 2
        expect(xsd_validate(doc)).to eq([])
      end
    end

    it 'validates urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:en16931' do
      doc = with_two_more_payment_means('spec/files/xsd/factur-x/factur-x-en16931.xml',
                                        'urn:cen.eu:en16931:2017#conformant#urn:factur-x.eu:1p0:en16931')
      expect(xsd_validate(doc)).to eq([])
    end
  end

  it 'has no xmlns link pointing at a missing schema' do
    dangling = Dir['lib/xsd/xmlns/*'].select { |link| File.symlink?(link) && !File.exist?(link) }
    expect(dangling).to eq([])
  end

  context 'check choose correct validator xsd path' do
    files = {
      'spec/files/xsd/factur-x/factur-x-minimum.xml' => /FACTUR-X_MINIMUM.xsd/,
      'spec/files/xsd/factur-x/factur-x-basic.xml' => /FACTUR-X_BASIC.xsd/,
      'spec/files/xsd/factur-x/factur-x-basic-wl.xml' => /FACTUR-X_BASIC-WL.xsd/,
      'spec/files/xsd/factur-x/factur-x-en16931.xml' => %r{factur-x/en16931/FACTUR-X_EN16931\.xsd},
      'spec/files/xsd/factur-x/factur-x-extended.xml' => /FACTUR-X_EXTENDED.xsd/,
      'spec/files/xsd/factur-x/factur-x-fr-extended-ctc-dot.xml' => /FACTUR-X_EXTENDED.xsd/,
      'spec/files/xsd/factur-x/factur-x-fr-extended-ctc-colon.xml' => /FACTUR-X_EXTENDED.xsd/,
      'spec/files/xsd/cii/zugferd_1.xml' => %r{cii_en16931/FACTUR-X_EN16931\.xsd},
      'spec/files/sch/cii/xrechnung-cii_3.0-wrong.xml' => 'CrossIndustryInvoice_100pD16B.xsd',
      'spec/files/sch/cii/xrechnung-cii_3.0_extension-wrong.xml' => 'CrossIndustryInvoice_100pD16B.xsd',
      'spec/files/xsd/cii/france_billing_cius.xml' => 'CrossIndustryInvoice_100pD22B.xsd',
      'spec/files/xsd/cii/france_billing_extended.xml' => 'CrossIndustryInvoice_100pD22B.xsd',
      'spec/files/xsd/factur-x/factur-x-france-billing.xml' => 'CrossIndustryInvoice_100pD22B.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.3-wrong.xml' => 'cii_en16931/FACTUR-X_EN16931.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.2-wrong.xml' => 'cii_en16931/FACTUR-X_EN16931.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.1.xml' => 'cii_en16931/FACTUR-X_EN16931.xsd',
      'spec/files/sch/cii/xrechnung-cii_2.0.xml' => 'cii_en16931/FACTUR-X_EN16931.xsd',
      'spec/files/xsd/fatturapa/IT01234567890_FPA03.xml' => '/fatturapa/Schema_del_file_xml_FatturaPA_v1.2.3.xsd',
      'spec/files/xsd/peppol-selfbilling-base.xml' => /UBL-Invoice-2.1.xsd/,
      'spec/files/xsd/peppol-selfbilling-creditnote.xml' => /UBL-CreditNote-2.1.xsd/,
      'spec/files/xsd/ksef/FA_3_Przykład_1.xml' => '/ksef/fa3.xsd',
      'spec/files/xsd/dgfip/tax_report_f1/fr_f1_base.xml' => '/dgfip/tax_report_f1_base_ubl_2_1/F1BASE_UBL-invoice-2.1.xsd',
      'spec/files/xsd/cdar/cdar_1_deposee.xml' => '/cdar/CrossDomainAcknowledgementAndResponse_100pD22B.xsd',
      'spec/files/xsd/dgfip/tax_report_f10/ventes.xml' => '/dgfip/tax_report_f10/ereporting.xsd',
      'spec/files/xsd/dgfip/tax_report_f10/acquisitions.xml' => '/dgfip/tax_report_f10/ereporting.xsd',
      'spec/files/xsd/dgfip/tax_report_f10/encaissements.xml' => '/dgfip/tax_report_f10/ereporting.xsd',
      'spec/files/xsd/sk-tdd.xml' => /sk_tdd\/Peppol-Slovak-Republic-TDD.xsd/,
      # A Peppol MLS has no UBLVersionID: the plain ApplicationResponse link gives UBL 2.1.
      'spec/files/xsd/mls/mls-ap.xml' => %r{ubl_21/maindoc/UBL-ApplicationResponse-2\.1\.xsd},
      'spec/files/xsd/dgfip/tax_report_f10/ventes_sans_transactions_count.xml' => '/dgfip/tax_report_f10/ereporting.xsd',
      'spec/files/xsd/dgfip/tax_report_f10/ventes_references_wrong.xml' => '/dgfip/tax_report_f10/ereporting.xsd',
      'spec/files/xsd/dgfip/annuaire_f14/export_complet.xml' => '/dgfip/annuaire_f14/consultation/Annuaire_Consultation_F14.xsd',
      'spec/files/xsd/dgfip/annuaire_f14/export_differentiel.xml' => '/dgfip/annuaire_f14/consultation/Annuaire_Consultation_F14.xsd',
      'spec/files/xsd/datev/document_v060.xml' => /datev\/Document_v060\.xsd/,
      'spec/files/xsd/datev/ledger_import_v060.xml' => /datev\/Belegverwaltung_online_ledger_import_v060\.xsd/,

    }
    files.each do |file_path, rgex_xsd_path|
      it "#{file_path} checks with #{rgex_xsd_path}" do
        expect(root_namespace_xsd(File.read(file_path))).to match(rgex_xsd_path)
      end
    end
  end
end
