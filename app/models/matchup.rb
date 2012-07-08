class Matchup < ActiveRecord::Base
  belongs_to :league
  
  # for an array of matchups return only the matchups that occur this week for a given league
  def self.this_week( matchup_array, week_in_league )
    weekly_matchups = []
    matchup_array.each do |m|
      if m.week == week_in_league
        weekly_matchups << m
      end # if to check that the weeks match
    end #loop to cycle through matchups array
    return weekly_matchups
  end #method def
  
end
