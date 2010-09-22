class UnifyUserName < ActiveRecord::Migration
  def self.up
    for user in connection.select_all("SELECT u.id, u.name, "+connection.concatenate("u.name", "'_'", "LOWER(c.code)")+" AS login FROM #{quoted_table_name(:users)} AS u JOIN #{quoted_table_name(:companies)} AS c ON (company_id=c.id) WHERE u.name in (SELECT name FROM #{quoted_table_name(:users)} GROUP BY name HAVING count(id)>1)")
      execute "UPDATE #{quoted_table_name(:users)} SET name='#{user['login']}' WHERE id=#{user['id']}"
    end
  end

  def self.down
  end
end
