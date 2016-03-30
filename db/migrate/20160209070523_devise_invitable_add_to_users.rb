class DeviseInvitableAddToUsers < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.string     :invitation_token
      t.datetime   :invitation_created_at
      t.datetime   :invitation_sent_at
      t.datetime   :invitation_accepted_at
      t.integer    :invitation_limit
      t.integer    :invited_by_id
      t.integer    :invitations_count, default: 0
      t.index      :invitations_count
      t.index      :invitation_token, unique: true # for invitable
      t.index      :invited_by_id
    end
  end

  def down
    change_table :users do |t|
      t.remove :invited_by_id, :invitations_count, :invitation_limit, :invitation_sent_at, :invitation_accepted_at, :invitation_token, :invitation_created_at
    end
  end
end
