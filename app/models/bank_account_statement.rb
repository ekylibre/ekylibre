# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: bank_account_statements
#
#  bank_account_id :integer          not null
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer          
#  credit          :decimal(16, 2)   default(0.0), not null
#  debit           :decimal(16, 2)   default(0.0), not null
#  id              :integer          not null, primary key
#  intermediate    :boolean          not null
#  lock_version    :integer          default(0), not null
#  number          :string(255)      not null
#  started_on      :date             not null
#  stopped_on      :date             not null
#  updated_at      :datetime         not null
#  updater_id      :integer          
#

class BankAccountStatement < ActiveRecord::Base
  belongs_to :bank_account
  belongs_to :company

  has_many :intermediate_entries, :class_name=>JournalEntry.name, :foreign_key=>:intermediate_id
  has_many :entries, :class_name=>JournalEntry.name, :foreign_key=>:statement_id, :dependent=>:nullify


  def before_validation
    self.company_id = self.bank_account.company_id if self.bank_account
    self.debit  = self.entries.sum(:debit)
    self.credit = self.entries.sum(:credit)
  end

  # A bank account statement has to contain all the planned records.
  def validate    
    errors.add_to_base tc(:error_period_statement) if self.started_on >= self.stopped_on
  end

  def eligible_entries
    self.company.journal_entries.find(:all, 
                                      :conditions =>["account_id = ? AND draft=? AND (statement_id IS NULL OR statement_id = ? OR journal_records.created_on BETWEEN ? AND ?)", self.bank_account.account_id, false, self.id, self.started_on, self.stopped_on], 
                                      :joins => "INNER JOIN journal_records ON journal_records.id = journal_entries.record_id", 
                                      :order => "statement_id DESC, journal_entries.created_at DESC")
  end

end
