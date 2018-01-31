# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: outgoing_payment_lists
#
#  cached_payment_count :integer
#  cached_total_sum     :decimal(, )
#  created_at           :datetime
#  creator_id           :integer
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  mode_id              :integer          not null
#  number               :string
#  updated_at           :datetime
#  updater_id           :integer
#
require 'test_helper'

class OutgoingPaymentListTest < ActiveSupport::TestCase
  setup { @list = outgoing_payment_lists(:outgoing_payment_lists_003) }

  test 'to_sepa' do
    Timecop.freeze(Time.new(2016, 10, 1, 11, 1, 35, '+02:00')) do
      doc = Nokogiri::XML(@list.to_sepa)
      doc.collect_namespaces
      doc.remove_namespaces!

      message_identification = "EKY-#{@list.number}-#{Time.now.utc.strftime('%y%m%d-%H%M')}"

      assert_equal(message_identification, doc.xpath('//CstmrCdtTrfInitn/GrpHdr/MsgId').text)
      assert_equal(Time.now.getlocal.iso8601, doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CreDtTm').text)
      assert_equal('1', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/NbOfTxs').text)
      assert_equal('8694.00', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CtrlSum').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/InitgPty/Nm').text)

      assert_equal("#{message_identification}/1", doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtInfId').text)
      assert_equal('TRF', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtMtd').text)
      assert_equal('false', doc.xpath('//CstmrCdtTrfInitn/PmtInf/BtchBookg').text)
      assert_equal('1', doc.xpath('//CstmrCdtTrfInitn/PmtInf/NbOfTxs').text)
      assert_equal('8694.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CtrlSum').text)
      assert_equal('SEPA', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtTpInf/SvcLvl/Cd').text)
      assert_equal(Time.zone.now.strftime('%Y-%m-%d').to_s, doc.xpath('//CstmrCdtTrfInitn/PmtInf/ReqdExctnDt').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/PmtInf/Dbtr/Nm').text)
      assert_equal('FR7611111222223333333333391', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAcct/Id/IBAN').text)
      assert_equal('GHBXFRPP', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAgt/FinInstnId/BIC').text)
      assert_equal('SLEV', doc.xpath('//CstmrCdtTrfInitn/PmtInf/ChrgBr').text)

      assert_equal('D20170004', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('PmtId/EndToEndId').text)
      assert_equal('8694.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath("Amt/InstdAmt[@Ccy='EUR']").text)
      assert_equal('ABNANL2AXXX', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAgt/FinInstnId/BIC').text)
      assert_equal('BAKTOUBI Inc.', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('Cdtr/Nm').text)
      assert_equal('NL72ABNA0897960274', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAcct/Id/IBAN').text)
      assert_equal('A201711000003', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('RmtInf/Ustrd').text)
    end
  end

  test 'to_sepa with BIC nil' do
    @list.mode.cash.update!(bank_identifier_code: nil)

    @list.payments.each do |payment|
      payment.payee.update!(bank_identifier_code: nil)
    end

    Timecop.freeze(Time.new(2016, 10, 1, 11, 1, 35, '+02:00')) do
      doc = Nokogiri::XML(@list.to_sepa)
      doc.collect_namespaces
      doc.remove_namespaces!

      message_identification = "EKY-#{@list.number}-#{Time.now.utc.strftime('%y%m%d-%H%M')}"

      assert_equal(message_identification, doc.xpath('//CstmrCdtTrfInitn/GrpHdr/MsgId').text)
      assert_equal(Time.now.getlocal.iso8601, doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CreDtTm').text)
      assert_equal('1', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/NbOfTxs').text)
      assert_equal('8694.00', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/CtrlSum').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/InitgPty/Nm').text)

      assert_equal("#{message_identification}/1", doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtInfId').text)
      assert_equal('TRF', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtMtd').text)
      assert_equal('false', doc.xpath('//CstmrCdtTrfInitn/PmtInf/BtchBookg').text)
      assert_equal('1', doc.xpath('//CstmrCdtTrfInitn/PmtInf/NbOfTxs').text)
      assert_equal('8694.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CtrlSum').text)
      assert_equal('SEPA', doc.xpath('//CstmrCdtTrfInitn/PmtInf/PmtTpInf/SvcLvl/Cd').text)
      assert_equal(Time.zone.now.strftime('%Y-%m-%d').to_s, doc.xpath('//CstmrCdtTrfInitn/PmtInf/ReqdExctnDt').text)
      assert_equal('John Doe', doc.xpath('//CstmrCdtTrfInitn/PmtInf/Dbtr/Nm').text)
      assert_equal('FR7611111222223333333333391', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAcct/Id/IBAN').text)
      assert_equal('NOTPROVIDED', doc.xpath('//CstmrCdtTrfInitn/PmtInf/DbtrAgt/FinInstnId/BIC').text)
      assert_equal('SLEV', doc.xpath('//CstmrCdtTrfInitn/PmtInf/ChrgBr').text)

      assert_equal('D20170004', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('PmtId/EndToEndId').text)
      assert_equal('8694.00', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath("Amt/InstdAmt[@Ccy='EUR']").text)
      assert_equal('NOTPROVIDED', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAgt/FinInstnId/BIC').text)
      assert_equal('BAKTOUBI Inc.', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('Cdtr/Nm').text)
      assert_equal('NL72ABNA0897960274', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('CdtrAcct/Id/IBAN').text)
      assert_equal('A201711000003', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('RmtInf/Ustrd').text)
    end
  end

  test 'to_sepa with latin characters for bank_account_holder_name' do
    @list.mode.cash.update!(bank_account_holder_name: 'Cédric Áttèntïòn')

    @list.payments.first.payee.update!(bank_account_holder_name: 'Còmptë cômpliqüé')

    Timecop.freeze(Time.zone.local(2016, 10, 1, 9, 1, 35)) do
      doc = Nokogiri::XML(@list.to_sepa)
      doc.collect_namespaces
      doc.remove_namespaces!

      assert_equal('Cedric Attention', doc.xpath('//CstmrCdtTrfInitn/GrpHdr/InitgPty/Nm').text)
      assert_equal('Cedric Attention', doc.xpath('//CstmrCdtTrfInitn/PmtInf/Dbtr/Nm').text)
      assert_equal('Compte complique', doc.xpath('//CstmrCdtTrfInitn/PmtInf/CdtTrfTxInf')[0].xpath('Cdtr/Nm').text)
    end
  end

  test 'destroy with bank_statement_letter present' do
    @list.payments.last.journal_entry.items.last.update_column(
      :bank_statement_letter, 'someting'
    )

    assert_raise(Ekylibre::Record::RecordNotDestroyable) { @list.destroy }
    assert(@list.reload.persisted?)
  end

  test 'destroy with all bank_statement_letter blank' do
    list = OutgoingPaymentList.all.detect do |l|
      JournalEntryItem.where(entry_id: l.payments.select(:entry_id))
                      .where(state: :closed).empty?
    end
    assert list, 'Cannot find a destroyable list'
    JournalEntryItem.where(entry_id: list.payments.select(:entry_id)).update_all(bank_statement_letter: nil)
    assert(list.remove)
    assert_raise(ActiveRecord::RecordNotFound) { list.reload }
  end

  test 'generate from purchase affairs' do
    affairs = PurchaseAffair.where(closed: false, currency: 'EUR')
    OutgoingPaymentList.build_from_affairs(affairs, OutgoingPaymentMode.where(cash: Cash.where(currency: 'EUR')).first, nil)
  end
end
