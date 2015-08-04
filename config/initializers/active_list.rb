# Sets default temporary in Rails tmp dir by default
if Rails.env.development?
  ActiveList.temporary_directory = -> { Rails.root.join('tmp', 'exports', 'active_list') }
else
  ActiveList.temporary_directory = -> { Ekylibre::Tenant.private_directory.join('tmp') }
end
