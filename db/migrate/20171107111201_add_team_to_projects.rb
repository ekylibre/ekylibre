class AddTeamToProjects < ActiveRecord::Migration[4.2]
  def change
    add_reference :projects, :team, index: true
  end
end
