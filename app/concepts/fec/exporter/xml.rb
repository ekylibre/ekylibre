module FEC
  module Exporter
    class XML < FEC::Exporter::Base
      private

      def build(journals)
        builder = Nokogiri::XML::Builder.new(encoding: 'ISO-8859-15') do |xml|
          xml.comptabilite do
            xml.exercice do
              xml.DateCloture @financial_year.stopped_on.strftime('%Y-%m-%d')
              journals.each do |journal|
                entries = journal.entries.between(@financial_year.started_on, @financial_year.stopped_on)
                next unless entries.any?
                xml.journal do
                  xml.JournalCode journal.code
                  xml.JournalLib journal.name
                  entries.includes(items: :account).references(items: :account).find_each do |entry|
                    next if entry.items.empty?
                    resource = Maybe(entry.resource)
                    xml.ecriture do
                      xml.EcritureNum (entry.continuous_number? ? entry.continuous_number : '')
                      xml.EcritureDate entry.printed_on.strftime('%Y-%m-%d')
                      xml.EcritureLib entry.items.first.name
                      xml.PieceRef entry.number
                      xml.PieceDate entry.created_at.strftime('%Y-%m-%d') # bug with resource.created_at.strftime('%Y-%m-%d')
                      xml.EcritureLet entry.letter if entry.letter
                      # xml.DateLet
                      xml.ValidDate (entry.validated_at? ? entry.validated_at.strftime('%Y-%m-%d') : '')
                      xml.DateRglt entry.first_payment.paid_at if entry.first_payment && fiscal_position == :ba_ir_cash_accountancy
                      xml.ModeRglt entry.first_payment.mode.name if entry.first_payment && fiscal_position == :ba_ir_cash_accountancy
                      xml.NatOp '' if fiscal_position == :ba_ir_cash_accountancy
                      xml.IdClient (resource.client? ? resource.client.number : (resource.supplier? ? resource.supplier.full_name : '')) if resource && fiscal_position == :bnc_ir_cash_accountancy

                      entry.items.find_each do |item|
                        xml.ligne do
                          xml.CompteNum item.account.number.ljust(3, '0')
                          xml.CompteLib item.account.name
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
