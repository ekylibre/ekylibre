# == Schema Information
# Schema version: 20080819191919
#
# Table name: journals
#
#  id             :integer       not null, primary key
#  nature_id      :integer       not null
#  name           :string(255)   not null
#  code           :string(4)     not null
#  counterpart_id :integer       
#  closed_on      :date          not null
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class Journal < ActiveRecord::Base
end
class JournalPeriod < ActiveRecord::Base
end
class JournalNature < ActiveRecord::Base
end
class JournalRecord < ActiveRecord::Base
end
class Entry < ActiveRecord::Base
end
class Currency < ActiveRecord::Base
end
class BankAccountStatement < ActiveRecord::Base
end
class BankAccount < ActiveRecord::Base
end
class Bank < ActiveRecord::Base
end
class Delay < ActiveRecord::Base
end
class Action < ActiveRecord::Base
end
class EntityNature < ActiveRecord::Base
end
class AddressNorm < ActiveRecord::Base
end
class AddressNormItem < ActiveRecord::Base
end
class Contact < ActiveRecord::Base
end
class FinancialyearNature < ActiveRecord::Base
end


