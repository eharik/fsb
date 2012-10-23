class AddSaltToLeagues < ActiveRecord::Migration
  def change
    add_column :leagues, :salt, :string
  end
end
