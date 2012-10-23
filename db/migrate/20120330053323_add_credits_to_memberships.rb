class AddCreditsToMemberships < ActiveRecord::Migration
  def change
       add_column :memberships, :credits, :text
  end
end
