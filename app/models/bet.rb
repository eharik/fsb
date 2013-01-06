class Bet < ActiveRecord::Base
  belongs_to :games
  belongs_to :user
  belongs_to :league
  
  has_many   :sub_bets, :class_name => "Bet", :foreign_key => "parlay_id"
  belongs_to :parlay,   :class_name => "Bet"

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
        return (bet_value + game.home_score) > game.away_score
      end
      if team == "away"
        return (bet_value + game.away_score) > game.home_score
      end
    end
  end

	def get_css_color
		game = Game.find(game_id)
		game_time = DateTime.strptime(game.game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)")
		return_string = self.winner?.to_s
		if !game.game_status.nil?
			return_string += " " + game.game_status
		end
		if game_time.past?
			return return_string
		else
			return "pending"
		end
	end

	def not_in_future?
		game = Game.find(game_id)
		game_time = DateTime.strptime(game.game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)")
		return game_time.past?
	end

	def in_future?
		return !self.not_in_future?
	end

	def in_progress?
		game = Game.find(game_id)
		return game.in_progress?
	end
  
  def update_bet_status
    if self.winner?
      self.won = true;
    else
      self.won = false;
    end
    self.save
		if self.parlay_sub_bet?
			parlay = Bet.find(parlay_id)
			if parlay.parlay_complete?
				parlay.update_parlay_bet_status
			end
		end
  end

	def parlay_sub_bet?
		return !parlay_id.nil?
	end

	def has_sub_bet_with_game? (game)
		self.sub_bets.each do |sub_bet|
			if sub_bet.game_id == game.id
				return true
			end		
		end
		return false		
	end

	def update_parlay_bet_status
		winner = true
		self.sub_bets.each do |bet|
			unless bet.winner?
				winner = false
			end
		end
		self.won = winner
		self.save
    m = Membership.where("league_id = ? AND
                          user_id   = ?",
                          self.league_id,
                          self.user_id).first
    m.update_credits_for_bet( self )
	end

	def parlay_complete?
		complete = true
		self.sub_bets.each do |bet|
			unless bet.complete?
				complete = false
			end
		end
		return complete
	end

	def complete?
		return (won == true || won == false)
	end
  
  def self.open_bets (league, user)
    all_bets_for_user_in_league = Bet.where("league_id = ? AND
                                             user_id   = ? AND
                                             lock      != ? AND
																						 game_id > ? AND
																						 risk > ?",
                                             league.id,
                                             user.id,
                                             true,
																						 0,0).all
    bets_for_return = []
    all_bets_for_user_in_league.each do |b|
      if b.in_future?
        bets_for_return << b
      end
    end
    return bets_for_return
  end

	def self.active_bets (league, user)
    active_bets_for_user_in_league = Bet.where("league_id = ? AND
                                             user_id   = ? AND
                                             lock      != ? AND
																						 game_id > ? AND
																						 risk > ?",
                                             league.id,
                                             user.id,
                                             true,
																						 0,0).all
    bets_for_return = []
		active_bets_for_user_in_league.each do |b|
      if b.in_progress?
        bets_for_return << b
      end
    end
    return bets_for_return
	end
  
  def self.past_bets (league, user)
    all_bets_for_user_in_league = Bet.where("league_id = ? AND
                                             user_id   = ? AND
                                             lock      != ? AND
																						 game_id > ? AND
																						 risk > ?",
                                             league.id,
                                             user.id,
                                             true,
																						 0,0).all
    bets_for_return = []
    all_bets_for_user_in_league.each do |b|
      if b.not_in_future?
        bets_for_return << b
      end
    end
    return bets_for_return
  end
 
	def self.parlays(league, user)
		parlays = Bet.where('league_id =  ? AND
                         user_id   =  ? AND
												 game_id = ?',
                         league.id,
                         user.id,
                         -1).all
		return parlays
	end

	def self.open_parlays( league, user)
		parlays = self.parlays( league, user )
		open_parlays = []
		parlays.each do |parlay|
			unless parlay.parlay_complete?
				open_parlays << parlay			
			end
		end
		return open_parlays
	end

  # ----- Updates Credits or Lock once Games Status Goes to Final -----#
  # ----- Checks that games status (won/loss) isn't already set -------#
  def self.update_bet_for_game( g )
    bets_to_update = Bet.where( "game_id = ? ", g.id ).all
    
    bets_to_update.each do |b|
      unless b.complete?
        b.update_bet_status
				unless b.parlay_sub_bet?
		      m = Membership.where("league_id = ? AND
		                            user_id   = ?",
		                            b.league_id,
		                            b.user_id).first
		      m.update_credits_for_bet( b )
				end
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
    game = Game.find(self.game_id)
    type = self.bet_type
    if over_under?
      line = game.over_under
    else
      line = game.spread
    end
    return line.abs
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
  
	#----- Is this a MNF game?                 ------------------#
	#----- Used when updating results to       ------------------#
	#-----    reduce the week number by one    ------------------#
	def mnf?
		game = Game.find(game_id)
		(game.game_time.to_datetime.utc - 4.hours).monday? ? true : false
		# removing four hours so that SNF games don't show up as MNF games
		#   which they would in utc time
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

