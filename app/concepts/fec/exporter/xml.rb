module FEC
  module Exporter
    class XML < FEC::Exporter::Base
      private

      def build(journals)
        validators = {
                       "all" => "formatA47A-I-VII-1.xsd",
                       "ba_bnc_ir_commercial_accountancy" => "formatA47A-I-VIII-3.xsd",
                       "ba_ir_cash_accountancy" => "formatA47A-I-VIII-5.xsd",
                       "bnc_ir_cash_accountancy" => "formatA47A-I-VIII-7.xsd"
                     }

        builder = Nokogiri::XML::Builder.new(encoding: 'ISO-8859-15') do |xml|
          xml.comptabilite('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:noNamespaceSchemaLocation' => validators[fiscal_position]) do
            xml.exercice do
              xml.DateCloture @financial_year.stopped_on.strftime('%Y-%m-%d')
              journals.each do |journal|
                entries = journal.entries.where.not(state: 'draft').between(@started_on, @stopped_on)
                next unless entries.any?
                xml.journal do
                  xml.JournalCode journal.code
                  xml.JournalLib journal.name
                  entries.includes(:incoming_payments, :purchase_payments, items: :account).references(items: :account).find_each do |entry|
                    next if entry.items.empty? || ((fiscal_position == 'ba_ir_cash_accountancy' || fiscal_position == 'bnc_ir_cash_accountancy') && !entry.first_payment)
                    resource = Maybe(entry.resource)
                    xml.ecriture do
                      xml.EcritureNum (entry.continuous_number? ? entry.continuous_number : '')
                      xml.EcritureDate entry.printed_on.strftime('%Y-%m-%d')
                      xml.EcritureLib CGI::escapeHTML(entry.items.first.name.dump[1...-1])
                      xml.PieceRef entry.number
                      xml.PieceDate entry.created_at.strftime('%Y-%m-%d') # bug with resource.created_at.strftime('%Y-%m-%d')
                      xml.EcritureLet entry.letter if entry.letter
                      # xml.DateLet
                      xml.ValidDate (entry.validated_at? ? entry.validated_at.strftime('%Y-%m-%d') : '')
                      xml.DateRglt entry.first_payment.paid_at.strftime('%Y-%m-%d') if entry.first_payment && fiscal_position == 'ba_ir_cash_accountancy'
                      xml.ModeRglt entry.first_payment.mode.name if entry.first_payment && fiscal_position == 'ba_ir_cash_accountancy'
                      xml.NatOp '' if fiscal_position == 'ba_ir_cash_accountancy'
                      xml.IdClient (resource.has_attribute?(:client_id).get && resource.client.get ? resource.client.get.number : (resource.has_attribute?(:supplier_id).get && resource.supplier.get ? resource.supplier.get.full_name : '')) if resource.is_some? && fiscal_position == 'bnc_ir_cash_accountancy'

                      entry.items.includes(:account).find_each do |item|
                        xml.ligne do
                          xml.CompteNum item.account.number.ljust(3, '0')
                          xml.CompteLib CGI::escapeHTML(item.account.name.dump[1...-1])
                          xml.CompteAuxNum ''
                          xml.CompteAuxLib ''
                          xml.Montantdevise ''
                          xml.Idevise ''
                          if item.debit > 0
                            xml.Debit format('%5.2f', item.debit) # .tr('.', ',')
                          else
                            xml.Credit format('%5.2f', item.credit) # .to_s.tr('.', ',')
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
        builder.to_xml
      end
    end
  end
end
