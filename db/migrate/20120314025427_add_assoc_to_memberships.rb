class AddAssocToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :user_id, :integer
    add_column :memberships, :league_id, :integer
  end
end
