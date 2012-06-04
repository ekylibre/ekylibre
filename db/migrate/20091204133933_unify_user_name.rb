class UnifyUserName < ActiveRecord::Migration
  def self.up
    for user in select_all("SELECT u.id, u.name, u.name||'_'||LOWER(c.code) AS login FROM users AS u JOIN companies AS c ON (company_id=c.id) WHERE u.name in (SELECT name FROM users GROUP BY 1 HAVING count(id)>1)")
      # puts "UPDATE users SET name='#{user['login']}' WHERE id=#{user['id']}"
      execute "UPDATE users SET name='#{user['login']}' WHERE id=#{user['id']}"
    end
  end

  def self.down
  end
end
