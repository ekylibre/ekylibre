# Interpolate private in paperclip
Paperclip.interpolates :tenant  do |attachment, style|
  Ekylibre::Tenant.private_directory.join("attachments")
end
