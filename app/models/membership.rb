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
    if b.lock
      if b.winner?
        # get matchup
        league = League.find(self.league_id)
        week = league.what_week
        matchup = Matchup.user_matchup( self.league_id, self.user_id, week )
        # if home team, increment home team score
        if matchup.home_team?( b.user_id )
          matchup.home_team_score += 1;
        else # if away team, increment away team score
          matchup.away_team_score += 1;
        end
        matchup.save
      else
        # do nothing
      end
    else
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
  end
  
  def self.update_credits_for_matchup ( m, bet_amount )
    home_user_membership = Membership.where( :league_id => m.league_id,
                                             :user_id => m.home_team_id ).first
    away_user_membership = Membership.where( :league_id => m.league_id,
                                             :user_id => m.away_team_id ).first
    # unless a bye week
    unless (m.away_team_id == -1 || m.home_team_id == -1)
    # check which team has more points
      if( m.home_team_score > m.away_team_score )
        home_user_membership.add_win
        away_user_membership.add_loss
        home_user_membership.add_credits( bet_amount )
        away_user_membership.subtract_credits( bet_amount )
      elsif ( m.away_team_score > m.home_team_score )
        away_user_membership.add_win
        home_user_membership.add_loss
        away_user_membership.add_credits( bet_amount )
        home_user_membership.subtract_credits( bet_amount )
      else
        away_user_membership.add_tie
        home_user_membership.add_tie
      end
      home_user_membership.save
      away_user_membership.save
    end
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
  
  def add_win
    record_array = parse_record
    record_array[0] += 1
    record = un_parse_record( record_array )
  end
  
  def add_loss
    record_array = parse_record
    record_array[1] += 1
    record = un_parse_record( record_array )
  end
  
  def add_tie
    record_array = parse_record
    record_array[2] += 1
    record = un_parse_record( record_array )
  end
  
  def add_credits( amount )
    current_credits = credits.current
    new_credit_amount = amount.to_f + current_credits.to_f
    credits.send("#{Time.now.to_s}=", new_credit_amount) 
    credits.send("current=", new_credit_amount)
  end
  
  def subtract_credits( amount )
    current_credits = credits.current
    new_credit_amount = current_credits.to_f - amount.to_f
    credits.send("#{Time.now.to_s}=", new_credit_amount) 
    credits.send("current=", new_credit_amount)
  end
  
  def parse_record
    char_array = record.split("/")
    if char_array.length == 2
      char_array << "0"
    end
    int_array = []
    char_array.each do |c|
      int_array << c.to_i
    end
    return int_array
  end
  
  def un_parse_record ( record_int_array )
    record_string = ""
    record_string += record_int_array[0].to_s
    record_string += "/"
    record_string += record_int_array[1].to_s
    record_string += "/"
    record_string += record_int_array[2].to_s
  end

end
