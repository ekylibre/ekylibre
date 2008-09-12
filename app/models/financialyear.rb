# == Schema Information
# Schema version: 20080819191919
#
# Table name: financialyears
#
#  id           :integer       not null, primary key
#  code         :string(12)    not null
#  nature_id    :integer       not null
#  closed       :boolean       not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  written_on   :date          not null
#  debit        :decimal(16, 2 default(0.0), not null
#  credit       :decimal(16, 2 default(0.0), not null
#  position     :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Financialyear < ActiveRecord::Base

end
