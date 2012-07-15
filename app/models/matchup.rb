class Matchup < ActiveRecord::Base
  belongs_to :league
  
  # ---------- for an array of matchups return only the matchups that occur this week for a given league
  def self.this_week( matchup_array, week_in_league )
    weekly_matchups = []
    matchup_array.each do |m|
      if m.week == week_in_league
        weekly_matchups << m
      end # if to check that the weeks match
    end #loop to cycle through matchups array
    return weekly_matchups
  end #method def
  
  # ---------- return matchup for given league, user, and week
  def self.user_matchup( league_id, user_id, week )
    matchups_for_week = Matchup.where( :league_id => league_id, :week => week )
    matchups_for_week.each do |m|
      if (m.home_team_id == user_id) || (m.away_team_id == user_id)
        return m
      end
    end
  end
  
  # --------- return games for the given matchup for the away team
  def get_away_team_games
    
  end
  
  # --------- return games for the given matchup for the home team
  def get_home_team_games
  end
  
end
