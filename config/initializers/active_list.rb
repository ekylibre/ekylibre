# Sets default temporary in Rails tmp dir by default
ActiveList.temporary_directory = if Rails.env.development?
                                   -> { Rails.root.join('tmp', 'exports', 'active_list') }
                                 else
                                   -> { Ekylibre::Tenant.private_directory.join('tmp') }
                                 end
