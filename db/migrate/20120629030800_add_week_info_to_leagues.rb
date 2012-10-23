class AddWeekInfoToLeagues < ActiveRecord::Migration
  def change
        add_column :leagues, :start_date, :datetime
        add_column :leagues, :number_of_weeks, :integer
        add_column :leagues, :schedule, :text
  end
end
