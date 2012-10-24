class Bet < ActiveRecord::Base
  belongs_to :games
  belongs_to :user
  belongs_to :league
  
  has_many   :sub_bets, :class_name => "Bet"
  belongs_to :parlay,   :class_name => "Bet", :foreign_key => "parlay_id"

  def winner?
    game = Game.find(game_id)
    total_score = game.home_score + game.away_score
    
    if bet_type == "under"
      return total_score < bet_value
    end
    
    if bet_type == "over"
      return total_score > bet_value
    end
    
    if bet_type == "lay"
      if team == "home"
        return (bet_value + game.away_score) < game.home_score
      end
      if team == "away"
        return (bet_value + game.home_score) < game.away_score
      end
    end
    
    if bet_type == "take"
      if team == "home"
        return (game.spread + game.home_score) > game.away_score
      end
      if team == "away"
        return (game.spread + game.away_score) > game.home_score
      end
    end
  end


	def get_css_color
		game = Game.find(game_id)
		game_time = DateTime.strptime(game.game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)")
		if game_time.past?
			return self.winner?
		else
			return "pending"
		end
	end
  
  def update_bet_status
    if self.winner?
      self.won = true;
    else
      self.won = false;
    end
    self.save
  end
  
  def self.open_bets (league, user)
    all_bets_for_user_in_league = Bet.where("league_id = ? AND
                                             user_id   = ? AND
                                             lock      != ?",
                                             league.id,
                                             user.id,
                                             true).all
    bets_for_return = []
    all_bets_for_user_in_league.each do |b|
      bet_game = Game.find(b.game_id)
      if DateTime.strptime(bet_game.game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)") > DateTime.now.utc.in_time_zone("Eastern Time (US & Canada)")
        bets_for_return << b
      end
    end
    return bets_for_return
  end
  
  def self.all_bets (league, user)
    all_bets_for_user_in_league = Bet.where("league_id = ? AND
                                             user_id   = ? AND
                                             lock      != ?",
                                             league.id,
                                             user.id,
                                             true).all
    bets_for_return = []
    all_bets_for_user_in_league.each do |b|
      bet_game = Game.find(b.game_id)
      if DateTime.strptime(bet_game.game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)") < DateTime.now.utc.in_time_zone("Eastern Time (US & Canada)")
        bets_for_return << b
      end
    end
    return bets_for_return
  end
 
  # ----- Updates Credits or Lock once Games Status Goes to Final -----#
  # ----- Checks that games status (won/loss) isn't already set -------#
  def self.update_bet_for_game( g )
    bets_to_update = Bet.where( "game_id = ? ", g.id ).all
    
    bets_to_update.each do |b|
      unless (b.won == true || b.won == false)
        b.update_bet_status
        m = Membership.where("league_id = ? AND
                              user_id   = ?",
                              b.league_id,
                              b.user_id).first
        m.update_credits_for_bet( b )
      end
    end
    
  end
  
  # ----- Returns the team names formatted for bet type ---- #
  def team_names
    game = Game.find(self.game_id)
    type = self.bet_type
    if over_under?
      return "#{game.away_team} vs #{game.home_team}"
    elsif type == "lay"
      if game.spread <= 0
        return game.home_team
      else
        return game.away_team
      end
    else
      if game.spread <= 0
        return game.away_team
      else
        return game.home_team
      end
    end
  end

	#-------- Based on bet_type and current line set the bet value ----#
	def set_bet_value
		self.bet_value = self.bet_line
  end
  
	#------- Set the 'team' field for spread bets ----#
	def set_team (game)

		if bet_type == "lay"
  		if game.spread < 0
    		self.team = "home"
  		end
  		if game.spread > 0
    		self.team = "away"
  		end
		end
		if bet_type == "take"
			if game.spread > 0
				self.team = "home"
			end
			if game.spread < 0
				self.team = "away"
			end
		end
		if bet_type == "over" || bet_type == "under"
				self.team = "-"
		end
	end

	# ----- Returns the line based on the bet type ----- #
  def bet_line
    return bet_value
  end


	def team_name (game)
		if bet_type == "lay"
  		if game.spread < 0
    			return game.home_team
  		end
  		if game.spread > 0
    		return game.away_team
  		end
		end
		if bet_type == "take"
			if game.spread > 0
				return game.home_team
			end
			if game.spread < 0
				return game.away_team
			end
		end
		if bet_type == "over" || bet_type == "under"
				return "#{game.away_team} @ #{game.home_team}"
		end
	end

	def number (game)
		if bet_type == "lay"
			if game.spread < 0
				return game.spread*-1
			end
			if game.spread > 0
				return game.spread
			end
		end
		if bet_type == "take"
			if game.spread > 0
				return game.spread
			end
			if game.spread < 0
				return game.spread*-1
			end
		end
		if bet_type == "over" || bet_type == "under"
				return game.over_under
		end
	end  
  
  private
  
  def over_under?
    if self.bet_type == "over" || self.bet_type == "under"
      return true
    else
      return false
    end
  end

end

