if @user.worker
  json.first_name @user.first_name
  json.last_name @user.last_name
  json.email @user.email
  json.language @user.language
  json.administrator @user.administrator

  if user.role 
    json.role do
      json.id @user.role_id
      json.name @user.role.name
      json.right @user.role.rights
  json.worker_id @user.worker.id
end
