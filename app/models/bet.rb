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
      return total_score < game.over_under
    end
    
    if bet_type == "over"
      return total_score > game.over_under
    end
    
    if bet_type == "lay"
      if game.spread < 0
        return (game.spread + game.home_score) > game.away_score
      end
      if game.spread > 0
        return (game.spread + game.home_score) < game.away_score
      end
    end
    
    if bet_type == "take"
      if game.spread < 0
        return (game.spread + game.home_score) < game.away_score
      end
      if game.spread > 0
        return (game.spread + game.home_score) > game.away_score
      end
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
                                             lock      = ?",
                                             league.id,
                                             user.id,
                                             false).all
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
                                             lock      = ?",
                                             league.id,
                                             user.id,
                                             false).all
    bets_for_return = []
    all_bets_for_user_in_league.each do |b|
      bet_game = Game.find(b.game_id)
      if DateTime.strptime(bet_game.game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)") < DateTime.now.utc.in_time_zone("Eastern Time (US & Canada)")
        bets_for_return << b
      end
    end
    return bets_for_return
  end
  
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
  
  private
  
  def over_under?
    if self.bet_type == "over" || self.bet_type == "under"
      return true
    else
      return false
    end
  end
  
end

