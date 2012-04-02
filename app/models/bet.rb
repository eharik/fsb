class Bet < ActiveRecord::Base
  belongs_to :games
  belongs_to :user
  belongs_to :league
  
  has_many   :sub_bets, :class_name => "Bet"
  belongs_to :parlay,   :class_name => "Bet", :foreign_key => "parlay_id"

end
