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
                      xml.EcritureNum entry.number
                      xml.EcritureDate entry.printed_on.strftime('%Y-%m-%d')
                      xml.EcritureLib entry.items.first.name
                      xml.PieceRef (resource.respond_to?(:number) ? resource.number : '')
                      xml.PieceDate resource.created_at.or_else(entry.created_at).strftime('%Y-%m-%d')
                      # xml.EcritureLet '' #[A47a-i-VII-1]
                      # xml.DateLet '' #[A47a-i-VII-1]
                      xml.ValidDate entry.printed_on.strftime('%Y-%m-%d') # TODO : replace by validated_at
                      # 'DateRglt' => ??? [A47a-i-VIII-5]
                      # 'ModeRglt' => ??? [A47a-i-VIII-5]
                      # 'NatOp'    => ??? [A47a-i-VIII-5]
                      # 'IdClient' => ??? [A47a-i-VIII-7]
                      
                      entry.items.find_each do |item|
                        xml.ligne do
                            xml.CompteNum item.account.number.ljust(3, '0')
                            xml.CompteLib item.account.name
                            # xml.CompteAuxNum ''
                            # xml.CompteAuxLib ''
                            # xml.Montantdevise ''
                            # xml.Idevise ''
                          if item.debit > 0
                            xml.Debit sprintf('%5.2f', item.debit) #.tr('.', ',')
                          else
                            xml.Credit sprintf('%5.2f', item.credit) #.to_s.tr('.', ',')
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
