# frozen_string_literal: true

module FEC
  module Exporter
    class XML < FEC::Exporter::Base
      private

        def build(datasource)
          validators = {
            "all" => "A47A-I-VII-1.xsd",
            "ba_bnc_ir_commercial_accountancy" => "A47A-I-VIII-3.xsd",
            "ba_ir_cash_accountancy" => "A47A-I-VIII-5.xsd",
            "bnc_ir_cash_accountancy" => "A47A-I-VIII-7.xsd"
          }

          builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.comptabilite('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:noNamespaceSchemaLocation' => validators[fiscal_position]) do
              xml.exercice do
                xml.DateCloture datasource[:date_cloture]
                journals = datasource[:journals]
                journals.each do |journal|
                  xml.journal do
                    xml.JournalCode journal[:code]
                    xml.JournalLib journal[:name]
                    entries = journal[:entries]
                    entries.each do |entry|
                      puts entry.inspect.yellow
                      xml.ecriture do
                        xml.EcritureNum entry[:continuous_number]
                        xml.EcritureDate entry[:printed_on].strftime('%Y-%m-%d')
                        xml.EcritureLib entry[:libelle]
                        xml.PieceRef entry[:number]
                        xml.PieceDate entry[:printed_on].strftime('%Y-%m-%d')
                        xml.EcritureLet entry[:letter]
                        xml.DateLet entry[:lettered_at]&.strftime('%Y-%m-%d') if entry[:lettered_at]
                        xml.ValidDate entry[:validated_at]&.strftime('%Y-%m-%d')
                        if %w[ba_ir_cash_accountancy bnc_ir_cash_accountancy].include?(fiscal_position)
                          xml.DateRglt entry[:date_rglt].strftime('%Y-%m-%d')
                          xml.ModeRglt entry[:mode_rglt]
                          xml.NatOp entry[:nat_op]
                        end
                        if fiscal_position == 'bnc_ir_cash_accountancy'
                          xml.IdClient entry[:id_client]
                        end

                        items = entry[:items]
                        items.each do |item|
                          xml.ligne do
                            xml.CompteNum item[:compte_num]
                            xml.CompteLib item[:compte_lib]
                            xml.CompteAuxNum item[:compte_aux_num] if item[:compte_aux_num]
                            xml.CompteAuxLib item[:compte_aux_lib] if item[:compte_aux_lib]
                            xml.Montantdevise item[:montant_devise]
                            xml.Idevise item[:i_devise]
                            if item[:debit].to_f > 0
                              xml.Debit item[:debit]
                            else
                              xml.Credit item[:credit]
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
