module FEC
  module Exporter
    class XML < FEC::Exporter::Base
      private

      def build(journals)
        builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.comptabilite do
            xml.exercice('DateCloture' => @financial_year.stopped_on.to_s) do
              journals.each do |journal|
                entries = journal.entries.between(@financial_year.started_on, @financial_year.stopped_on)
                next unless entries.any?
                xml.journal('JournalCode' => journal.code, 'JournalLib' => journal.name) do
                  entries.includes(items: :account).references(items: :account).find_each do |entry|
                    next if entry.items.empty?
                    resource = Maybe(entry.resource)
                    attributes = {
                      'EcritureNum' => entry.number,
                      'EcritureDate' => entry.printed_on.to_s,
                      'EcritureLib' => entry.items.first.name,
                      'PieceRef' => resource.number.or_else(''),
                      'PieceDate' => resource.created_at.to_date.or_else(''),
                      # 'EcritureLet' => ??? [A47a-i-VII-1]
                      # 'DateLet'     => ??? [A47a-i-VII-1]
                      # 'DateRglt' => ??? [A47a-i-VIII-5]
                      # 'ModeRglt' => ??? [A47a-i-VIII-5]
                      # 'NatOp'    => ??? [A47a-i-VIII-5]
                      # 'IdClient' => ??? [A47a-i-VIII-7]
                    }
                    attributes['ValidDate'] = entry.printed_on.to_s if entry.confirmed?
                    if resource.respond_to?(:third)
                      attributes['TiersNum'] = resource.third.number.or_else('')
                      attributes['TiersLib'] = resource.third.full_name.or_else('')
                    end
                    xml.ecriture(attributes) do
                      entry.items.find_each do |item|
                        attributes = {
                          'CompteNum' => item.account.number,
                          'CompteLib' => item.account.name,
                          # "CompteAuxNum" => ???,
                          # "CompteAuxLib" => ???,
                          # "Montantdevise" => [item.real_debit, item.real_credit].max,
                          # "Idevise" => item.real_currency
                        }
                        if item.debit > 0
                          attributes['Debit'] = item.debit
                        else
                          attributes['Credit'] = item.credit
                        end
                        xml.ligne(attributes)
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
