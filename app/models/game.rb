class Game < ActiveRecord::Base
  attr_accessible :home_team, :away_team, :spread,
    :over_under, :game_time, :home_score, :away_score,
    :game_id
    
  require 'date'
  require 'nokogiri'
  require 'time'
  
  def self.open_games
    self.update_games
    Game.where("game_time > ?", DateTime.now)
  end
  
  def self.update_games
    require 'open-uri'
    url = "http://espn.go.com/nba/lines"
    doc = Nokogiri::HTML(open(url))
    
    @games = get_game_teams(doc)
    @lines = get_game_lines(doc)
    @home_teams = get_home_teams(@games)
    @away_teams = get_away_teams(@games)
    @over_unders = get_over_unders(@lines)
    @spreads = get_spreads(@lines)
    @game_times = get_game_times(doc)
    
    @game_ids = []
    for i in 0..(@games.length-1)
      @game_ids << "#{@away_teams[i]}:#{@home_teams[i]}:#{@game_times[i]}"

      if Game.find_by_game_id(@game_ids[i])
        Game.find_by_game_id(@game_ids[i]).spread = @spreads[i]
        Game.find_by_game_id(@game_ids[i]).over_under = @over_unders[i]
      else
        Game.create( "game_id"    => @game_ids[i],
                     "home_team"  => @home_teams[i],
                     "away_team"  => @away_teams[i],
                     "spread"     => @spreads[i].to_f,
                     "over_under" => @over_unders[i].to_f,
                     "game_time"  => @game_times[i],
                     "home_score" => 0,
                     "away_score" => 0
                    )

      end
    end
  end
  
  def self.get_game_times(doc)
    times = []
    doc.css(".stathead").each do |matchup|
      temp_hour = matchup.at_css("td").text[/[0-9]+:/]
      temp_hour = temp_hour[0..-2]
      temp_min = matchup.at_css("td").text[/:[0-9]+/]
      temp_min = temp_min[1..-1]
      if Integer(temp_hour) < 12
        temp_hour = (Integer(temp_hour) + 12).to_s
      end
      
      times << DateTime.new(DateTime.now.year, DateTime.now.month,
                            DateTime.now.day, Integer(temp_hour),
                            Integer(temp_min), 0, get_offset )
    end 
    return times
  end
  
  def self.get_game_teams(doc)
    games = []
    doc.css(".stathead").each do |matchup|
      games << matchup.at_css("td").text[/[\sa-zA-Z]+/]
    end
    return games
  end
  
  def self.get_game_lines(doc)
    lines = []
    doc.css(".sortcell").each do |matchup|
      lines << matchup.text
    end
    return lines
  end
  
  def self.get_home_teams(games)
    teams = []
    games.each do |game|
      teams << game[/[a-zA-Z]+(\s[A-Z])?[a-zA-Z]*/]
    end
    return teams
  end

  def self.get_away_teams(games)
    teams = []
    games.each do |game|
      temp_team = game[/at\s[a-zA-Z]+\s?[a-zA-Z]*/]
      teams << temp_team[3..-1]
    end
    return teams
  end

  def self.get_over_unders(lines)
    over_unders = []
    lines.each do |line|
      over_unders << line[/[0-9]+\.[0-9]+/]
    end
    return over_unders
  end
  
  def self.get_spreads(lines)
    spreads = []
    lines.each do |line|
      spreads << line[/[\-\+][0-9]+\.[0-9]+/]
    end
    return spreads
  end

  private
  
  def self.get_offset
    Rational(Time.now.utc.in_time_zone("Eastern Time (US & Canada)").utc_offset, 60*60*24)
  end
end
