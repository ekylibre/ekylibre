# frozen_string_literal: true

module FEC
  module Exporter
    class CSV < FEC::Exporter::Base
      private

        def build(datasource)
          columns = %w[JournalCode JournalLib EcritureNum EcritureDate CompteNum CompteLib CompAuxNum CompAuxLib PieceRef PieceDate EcritureLib Debit Credit EcritureLet DateLet ValidDate Montantdevise Idevise]

          if %w[ba_ir_cash_accountancy bnc_ir_cash_accountancy].include?(@fiscal_position)
            columns << 'DateRglt'
            columns << 'ModeRglt'
            columns << 'NatOp'
          end

          if @fiscal_position == 'bnc_ir_cash_accountancy'
            columns << 'IdClient'
          end

          rows = []
          datasource[:journals].each do |journal|
            journal[:entries].each do |entry|
              entry[:items].each do |item|
                datas = []
                datas << journal[:code]
                datas << journal[:name]
                datas << entry[:continuous_number]
                datas << entry[:date].strftime('%Y%m%d')
                datas << item[:compte_num]
                datas << item[:compte_lib]
                datas << item[:compte_aux_num]
                datas << item[:compte_aux_lib]
                datas << entry[:number]
                datas << entry[:date].strftime('%Y%m%d')
                datas << entry[:libelle]
                datas << item[:debit].to_s.tr('.', ',')
                datas << item[:credit].to_s.tr('.', ',')
                datas << entry[:letter]
                datas << entry[:lettered_at]&.strftime('%Y%m%d')
                datas << entry[:validated_at]&.strftime('%Y%m%d')
                datas << item[:montant_devise]
                datas << item[:i_devise]
                if %w[ba_ir_cash_accountancy bnc_ir_cash_accountancy].include?(@fiscal_position)
                  datas << entry[:date_rglt].strftime('%Y%m%d')
                  datas << entry[:mode_rglt]
                  datas << entry[:nat_op]
                end
                if @fiscal_position == 'bnc_ir_cash_accountancy'
                  datas << entry[:id_client]
                end
                rows << datas
              end
            end
          end
          # We need to sort the rows by the entry continuous number before inserting them into the CSV file, as there is no column associated to data we use the position in the array
          rows.sort_by! { |r| r[2] }

          ::CSV.generate col_sep: "|", encoding: 'UTF-8' do |csv|
            csv << columns
            rows.each do |row|
              csv << row
            end
          end
        end
    end
  end
end
