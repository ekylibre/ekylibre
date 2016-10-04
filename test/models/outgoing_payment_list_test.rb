require 'test_helper'

class OutgoingPaymentListTest < ActiveSupport::TestCase
  setup { @list = outgoing_payment_lists(:outgoing_payment_lists_001) }

  test 'to_sepa' do
    Timecop.freeze(Time.zone.local(2016, 10, 1, 9, 1, 35)) do
      doc = Nokogiri::XML(@list.to_sepa)
      doc.collect_namespaces
      doc.remove_namespaces!

      message_identification = "EKY-#{@list.number}-161001-0901"

      assert_equal(message_identification, doc.xpath('//CstmrCdtTrfInitn/GrpHdr/MsgId').text)
      assert_equal('2016-10-01T11:01:35+02:00', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CreDtTm').text)
      assert_equal('2', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/NbOfTxs').text)
      assert_equal('3561.00', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CtrlSum').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/InitgPty/Nm').text)

      assert_equal("#{message_identification}/1", doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtInfId').text)
      assert_equal('TRF', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtMtd').text)
      assert_equal('false', doc.xpath('//CstmrCdtTrfInitn/PmtInf/BtchBookg').text)
      assert_equal('2', doc.xpath('//CstmrCdtTrfInitn/PmtInf/NbOfTxs').text)
      assert_equal('3561.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CtrlSum').text)
      assert_equal('SEPA', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtTpInf/SvcLvl/Cd').text)
      assert_equal('2016-10-01T09:01:35Z', doc.xpath('//CstmrCdtTrfInitn/PmtInf/ReqdExctnDt').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/PmtInf/Dbtr/Nm').text)
      assert_equal('FR7611111222223333333333391', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAcct/Id/IBAN').text)
      assert_equal('GHBXFRPP', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAgt/FinInstnId/BIC').text)
      assert_equal('SLEV', doc.xpath('//CstmrCdtTrfInitn/PmtInf/ChrgBr').text)

      assert_equal('D20160003', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('PmtId/EndToEndId').text)
      assert_equal('1800.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath("Amt/InstdAmt[@Ccy='EUR']").text)
      assert_equal('ABNANL2AXXX', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAgt/FinInstnId/BIC').text)
      assert_equal('BAKTOUBI Inc.', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('Cdtr/Nm').text)
      assert_equal('NL72ABNA0897960274', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAcct/Id/IBAN').text)
      assert_equal('A201411000001', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('RmtInf/Ustrd').text)

      assert_equal('D20160004', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('PmtId/EndToEndId').text)
      assert_equal('1761.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath("Amt/InstdAmt[@Ccy='EUR']").text)
      assert_equal('TRIONL2UXXX', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('CdtrAgt/FinInstnId/BIC').text)
      assert_equal("Coop Ain Coop'In", doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('Cdtr/Nm').text)
      assert_equal('NL64TRIO0393404405', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('CdtrAcct/Id/IBAN').text)
      assert_equal('A201411000002', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('RmtInf/Ustrd').text)
    end
  end

  test 'to_sepa with BIC nil' do
    @list.mode.cash.update!(bank_identifier_code: nil)

    @list.payments.each do |payment|
      payment.payee.update!(bank_identifier_code: nil)
    end

    Timecop.freeze(Time.zone.local(2016, 10, 1, 9, 1, 35)) do
      doc = Nokogiri::XML(@list.to_sepa)
      doc.collect_namespaces
      doc.remove_namespaces!

      message_identification = "EKY-#{@list.number}-161001-0901"

      assert_equal(message_identification, doc.xpath('//CstmrCdtTrfInitn/GrpHdr/MsgId').text)
      assert_equal('2016-10-01T11:01:35+02:00', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CreDtTm').text)
      assert_equal('2', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/NbOfTxs').text)
      assert_equal('3561.00', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CtrlSum').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/InitgPty/Nm').text)

      assert_equal("#{message_identification}/1", doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtInfId').text)
      assert_equal('TRF', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtMtd').text)
      assert_equal('false', doc.xpath('//CstmrCdtTrfInitn/PmtInf/BtchBookg').text)
      assert_equal('2', doc.xpath('//CstmrCdtTrfInitn/PmtInf/NbOfTxs').text)
      assert_equal('3561.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CtrlSum').text)
      assert_equal('SEPA', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtTpInf/SvcLvl/Cd').text)
      assert_equal('2016-10-01T09:01:35Z', doc.xpath('//CstmrCdtTrfInitn/PmtInf/ReqdExctnDt').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/PmtInf/Dbtr/Nm').text)
      assert_equal('FR7611111222223333333333391', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAcct/Id/IBAN').text)
      assert_equal('NOTPROVIDED', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAgt/FinInstnId/BIC').text)
      assert_equal('SLEV', doc.xpath('//CstmrCdtTrfInitn/PmtInf/ChrgBr').text)

      assert_equal('D20160003', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('PmtId/EndToEndId').text)
      assert_equal('1800.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath("Amt/InstdAmt[@Ccy='EUR']").text)
      assert_equal('NOTPROVIDED', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAgt/FinInstnId/BIC').text)
      assert_equal('BAKTOUBI Inc.', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('Cdtr/Nm').text)
      assert_equal('NL72ABNA0897960274', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAcct/Id/IBAN').text)
      assert_equal('A201411000001', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('RmtInf/Ustrd').text)

      assert_equal('D20160004', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('PmtId/EndToEndId').text)
      assert_equal('1761.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath("Amt/InstdAmt[@Ccy='EUR']").text)
      assert_equal('NOTPROVIDED', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('CdtrAgt/FinInstnId/BIC').text)
      assert_equal("Coop Ain Coop'In", doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('Cdtr/Nm').text)
      assert_equal('NL64TRIO0393404405', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('CdtrAcct/Id/IBAN').text)
      assert_equal('A201411000002', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[1].xpath('RmtInf/Ustrd').text)
    end
  end

  test 'destroyable? with bank_statement_letter present' do
    @list.payments.last.journal_entry.items.last.update_column(
      :bank_statement_letter, 'someting'
    )

    assert_not(@list.destroyable?, 'returns false')
  end

  test 'destroyable? with all bank_statement_letter blank' do
    assert(@list.destroyable?, 'returns true')
  end

  test 'destroy with bank_statement_letter present' do
    @list.payments.last.journal_entry.items.last.update_column(
      :bank_statement_letter, 'someting'
    )

    assert_raise(Ekylibre::Record::RecordNotDestroyable) { @list.destroy }
  end

  test 'destroy with all bank_statement_letter blank' do
    assert(@list.destroy)
  end
end
