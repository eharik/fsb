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
  
  # ----- Return matchups for a given league and week ----- #
  def self.league_matchups( league_id, week_in_league )
    return Matchup.where( :league_id => league_id,
                          :week => week_in_league ).all
  end
  
  # ---------- return matchup for given league, user, and week
  def self.user_matchup( league_id, user_id, week )
    matchups_for_week = Matchup.where( :league_id => league_id, :week => week ).all
    matchups_for_week.each do |m|
      if (m.home_team_id == user_id) || (m.away_team_id == user_id)
        return m
      end
    end
		return nil
  end
  
  # --------- return games for the given matchup for the away team
  def get_away_team_bets( league_id, current_user_id )
    away_user = User.find(self.away_team_id)
    return away_user.this_weeks_locks( League.find(league_id), current_user_id )
  end
  
  # --------- return games for the given matchup for the home team
  def get_home_team_bets( league_id, current_user_id )
    home_user = User.find(self.home_team_id)
    return home_user.this_weeks_locks( League.find(league_id), current_user_id )
  end

  # ------ return true if the user_id passed represents the home team #
  def home_team? ( user_id )
    return self.home_team_id == user_id
  end
  
    # ------ return true if the user_id passed represents the away team #
  def away_team? ( user_id )
    return self.away_team_id == user_id
  end
  
  
end
