# -*- coding: utf-8 -*-
require 'zip'
module Ekylibre
  module Export
    # Starts from 1 under IsaCompta
    class AccountancySpreadsheet
      @@format = [
        [3,  'jel.journal.code[0..1]'], # Code journal
        [8,  'jel.entry.number[0..1]+jel.entry.number[-6..-1]'], # Numéro de pièce
        [8,  'fdt(jel.entry.printed_on)'], # Date.pièce
        [30, 'jel.name'], # Libllé de l'écriture
        [3,  'jel.entry.currency.code'], # Devise
        [10, 'jel.account.number'], # N° compte
        [10, ''], # Compte centralisateur
        [30, 'jel.account.name'], # Libellé du compte
        [30, 'jel.name'], # Libellé du mouvement
        [13, '(100*jel.debit).to_i', 'r'], # Débit centimes
        [13, '(100*jel.credit).to_i', 'r'], # Crédit
        [11, ''], # Qté 1
        [11, ''], # Qté 2
        [8,  'jel.position', 'r'], # Numéro
        [4,  ''], # Code TVA
        [3,  'jel.letter'], # Lettrage
        [8,  'jel.bank_statement ? fdt(jel.bank_statement.stopped_on) : nil'], # Date de pointage
        [10, ''], # Activité
        [2,  ''], # Découpe de l'act
        [40, ''], # Libellé de l'act
        [4,  ''], # Code TVA associé au compte TVA
        [8,  ''], # Date échéance
        [10, ''], # Compte de contepartie
        [8,  '']  # Date sur mouvement
      ]

      def self.generate(_started_on, _stopped_on, filename = nil)
        carre = ''
        code = ''
        code += "JournalEntryLine.includes(:journal, {:entry => :currency}, :account, :bank_statement).where('NOT (#{JournalEntryLine.table_name}.debit = 0 AND #{JournalEntryLine.table_name}.credit = 0) AND printed_on BETWEEN ? AND ?', started_on, stopped_on).order('journals.name, journal_entries.number').find_each do |jel|\n"
        code += '      f.puts('
        for column in @@format
          if column[1].blank?
            code += "'" + (' ' * column[0]) + "'+"
          else
            x = "(ic.iconv((#{column[1]}).to_s) rescue (#{column[1]}).to_s.simpleize)"
            code += "#{x}.#{column[2] || 'l'}just(#{column[0]})[0..#{column[0] - 1}]+"
            # code += "(ic.iconv((#{column[1]}).to_s.#{'l'||column[2]||'l'}just(#{column[0]})[0..#{column[0]-1}]) rescue ((#{column[1]}).to_s.#{'l'||column[2]||'l'}just(#{column[0]})[0..#{column[0]-1}]).simpleize)+"
          end
        end
        code += '"\r\n"' + ")\n"
        code += "end\n"
        ic = Iconv.new('cp1252', 'utf-8')
        filename ||= 'COMPTA.ECC'
        file = Rails.root.join('tmp', "#{filename}.zip")

        Zip::File.open(file, Zip::File::CREATE) do |zile|
          zile.get_output_stream(filename) do |_f|
            eval(code)
          end
        end

        file
      end

      private

      def self.fdt(date)
        date.day.to_s.rjust(2, '0') + date.month.to_s.rjust(2, '0') + date.year.to_s.rjust(4, '0')
      end
    end
  end
end
