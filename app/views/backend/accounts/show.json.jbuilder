json.extract! resource, :id, :number, :nature

json.has_auxiliary_accounts resource.auxiliary_accounts.count > 0 if resource.centralizing?
