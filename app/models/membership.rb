class Membership < ActiveRecord::Base
  require 'ostruct'
  belongs_to :user
  belongs_to :league
  
  serialize  :credits, OpenStruct
  
  attr_accessor :league_name, :league_password
  
  def unlock_buy_in
  end
  
  def unlock_buy_back
  end
  
  def sufficient_funds? ( risk_amount )
    current_league = League.find(league_id)
    u = User.find(user_id)
    h2h_credits_required = current_league.league_settings["h2h_bet"]
    
    (credits.current.to_f - risk_amount.to_f - u.open_bets_risk(current_league).to_f) >= h2h_credits_required.to_f
  end
  
  def update_credits_for_risk ( risk_amount )
    new_credit_amount = credits.current.to_f - risk_amount.to_f
    credits.send("#{Time.now.to_s}=", new_credit_amount) 
    credits.send("current=", new_credit_amount)
  end
  
  def update_credits_for_bet ( b )
    win_credit_amount =  credits.current.to_f + b.win
    loss_credit_amount = credits.current.to_f - b.risk
    if b.winner?
      credits.send("#{Time.now.to_s}=", win_credit_amount) 
      credits.send("current=", win_credit_amount)
    else
      credits.send("#{Time.now.to_s}=", loss_credit_amount) 
      credits.send("current=", loss_credit_amount)      
    end
    self.save
  end
  
  def number_of_bets
    return Bet.open_bets( League.find(league_id), User.find(user_id) ).length + Bet.all_bets( League.find(league_id), User.find(user_id) ).length 
  end
  
  def win_percentage
    bets = Bet.all_bets( League.find(league_id), User.find(user_id) )
    total = bets.length.to_f
    won = 0;
    bets.each do |b|
      if b.won
        won += 1
      end
    end
    
    unless total == 0
      return sprintf( "%d\%",(won.to_f/total)*100 )
    end
    return sprintf( "%d\%", 0 )
  end
  
  def biggest_win
    bets = Bet.all_bets( League.find(league_id), User.find(user_id) )
    biggest = 0
    bets.each do |b|
      if b.won
        if b.win > biggest
          biggest = b.win
        end
      end
    end
    
    return sprintf( "%d Credits", biggest)
  end
  
  def biggest_loss
    bets = Bet.all_bets( League.find(league_id), User.find(user_id) )
    biggest = 0
    bets.each do |b|
      if !b.won
        if b.risk > biggest
          biggest = b.risk
        end
      end
    end
    
    return sprintf( "%d Credits", biggest)
  end
  
  def league_average
    l = League.find(league_id)
    m = l.memberships
    num_m = m.length
    won = 0;
    total = 0;
    
    m.each do |member|
      bets = Bet.all_bets( League.find(member.league_id), User.find(member.user_id) )
      total += bets.length.to_f
      bets.each do |b|
        if b.won
          won += 1
        end
      end
    end
    
    unless total.to_f == 0
      return sprintf( "%d\%",(won.to_f/total.to_f)*100 )
    end
    return sprintf( "%d\%", 0 )
    
  end
  
  def average_return
    bets = Bet.all_bets( League.find(league_id), User.find(user_id) )
    number_of_bets = bets.length
    total_won = 0
    total_lost = 0
    bets.each do |b|
      if b.won
        total_won += b.win
      end
      if !b.won
        total_lost += b.risk
      end
    end
    
    unless number_of_bets.to_f == 0
      return sprintf( "%d Credits", (total_won.to_f-total_lost.to_f)/number_of_bets.to_f)
    end
    return sprintf( "%d Credits", 0)
    
  end
  
  def get_plot_data
    k = credits.marshal_dump.keys[1..-1]
    v = credits.marshal_dump.values[1..-1]
    plot_data = Array.new(k.length){ Array.new(2) }
    for i in 0..(k.length-1)
      temp_date = k[i].to_s.to_time
      plot_data[i][0] = temp_date.to_i * 1000
      plot_data[i][1] = v[i]
    end
    return plot_data
  end
  
  def bump_credits(league)
    current_credits = credits.current
    bump_amount = league.league_settings['start_credits']
    new_credit_amount = bump_amount.to_f + current_credits.to_f
    credits.send("#{Time.now.to_s}=", new_credit_amount) 
    credits.send("current=", new_credit_amount)
    self.save
  end
  
  def su_credit_update(new_credit_amount)
    credits.send("#{Time.now.to_s}=", new_credit_amount) 
    credits.send("current=", new_credit_amount)
    self.save
  end
end
