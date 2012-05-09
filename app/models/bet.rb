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
    
    if bet_type == "give"
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
                                             user_id   = ?",
                                             league.id,
                                             user.id).all
    bets_for_return = []
    all_bets_for_user_in_league.each do |b|
      bet_game = Game.find(b.game_id)
      if bet_game.game_time > Time.now
        bets_for_return << b
      end
    end
    return bets_for_return
  end
  
  def self.all_bets (league, user)
    all_bets_for_user_in_league = Bet.where("league_id = ? AND
                                             user_id   = ?",
                                             league.id,
                                             user.id).all
    bets_for_return = []
    all_bets_for_user_in_league.each do |b|
      bet_game = Game.find(b.game_id)
      if bet_game.game_time < Time.now
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
  
end
