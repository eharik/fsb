class Game < ActiveRecord::Base
  attr_accessible :home_team, :away_team, :spread,
    :over_under, :game_time, :home_score, :away_score,
    :game_id, :game_status
    
  require 'date'
  require 'nokogiri'
  require 'time'
  require 'open-uri'
  
  def self.open_games
    Game.where("game_time > ?", DateTime.now)
  end
  
  def self.update_scores
    puts "**********updating_game_scores --> #{Time.now} **************"
    url = "http://espn.go.com/nfl/scoreboard"
    doc = Nokogiri::HTML(open(url))
    
    home_teams = get_home_teams2(doc)
    away_teams = get_away_teams2(doc)
    home_team_scores = get_scores_home(doc)
    away_team_scores = get_scores_away(doc)
    game_status = get_game_status(doc)
    games = get_games(home_teams, away_teams)
    update_game_scores(games, home_team_scores, away_team_scores, game_status)
  end
  
  def self.update_games
    puts "**********updating_available_games**************"
    url = "http://bovada.net/sports/odds/nfl"
    doc = Nokogiri::HTML(open(url))
  
    @home_teams = get_home_teams_bovada(doc)
    @away_teams = get_away_teams_bovada(doc)
    @over_unders = get_over_unders_bovada(doc)
    @spreads = get_spreads_bovada(doc)   
    @game_times = get_game_times_bovada(doc)
    
    @game_ids = []
    game_id_count = -1
    for i in 0..(@home_teams.length-1)
      if @over_unders[i] > 0
        game_id_count += 1
        @game_ids << "#{@away_teams[i]}:#{@home_teams[i]}:#{@game_times[i]}"
        
        if Game.find_by_game_id(@game_ids[game_id_count])
          Game.find_by_game_id(@game_ids[game_id_count]).update_attributes(:spread => @spreads[i], :over_under => @over_unders[i])
        else
          Game.create( "game_id"    => @game_ids[game_id_count],
                       "home_team"  => @home_teams[i],
                       "away_team"  => @away_teams[i],
                       "spread"     => @spreads[i].to_f,
                       "over_under" => @over_unders[i].to_f,
                       "game_time"  => @game_times[i],
                       "home_score" => 0,
                       "away_score" => 0
                      )
        end # end if on finding existing game
      end # end if on over unders
    end # end for loop through available games
  end
  
  def game_time_and_status
    gt = DateTime.strptime(game_time, "%Y-%m-%d %H:%M:%S").utc.in_time_zone("Eastern Time (US & Canada)").strftime("%b %d, %I:%M %p")
    unless DateTime.strptime(game_time, "%Y-%m-%d %H:%M:%S").future?
      return sprintf("%-20s %12s", gt, game_status)
    end
    return sprintf("%-20s %12s", gt, '------')
  end

  def home_team_with_score
    #home_score = 0 if home_score.nil?
    unless DateTime.strptime(game_time, "%Y-%m-%d %H:%M:%S").future?
      return sprintf("%-28s %3.0f", home_team, home_score )
    end
    return sprintf("%-28s TBD", home_team )
  end
  
  def away_team_with_score
    #away_score = 0 if away_score.nil?
    unless DateTime.strptime(game_time, "%Y-%m-%d %H:%M:%S").future?
      return sprintf("%-28s %3.0f", away_team, away_score)
    end
    return sprintf("%-28s TBD", away_team )
  end
  
  private
  
    def self.get_home_teams_bovada(doc)
      home_team = []
      doc.css(".home .competitor-name div").each do |team|
        home_team << team.text
      end
      return home_team
    end
    
    def self.get_away_teams_bovada(doc)
      away_team = []
      doc.css(".away .competitor-name div").each do |team|
        away_team << team.text
      end
      return away_team
    end
    
    def self.get_over_unders_bovada(doc)
      ou = []
      doc.css("b").each do |line|
        whole_part = line.text[/[0-9]+/].to_f
        fraction_part = line.text[/\u00BD/] ? 0.5 : 0.0
        temp = whole_part + fraction_part
        ou << temp
      end
      return ou
    end
    
    def self.get_spreads_bovada(doc)
      spread = []
      doc.css(".home .runline div").each do |line|
        whole_part = line.text[/\-*[0-9]+/].to_f
        fraction_part = line.text[/\u00BD/] ? 0.5 : 0.0
        if whole_part < 0 
          temp = whole_part - fraction_part
        else
          temp = whole_part + fraction_part
        end #c heck pos/neg
        spread << temp
      end # loop through doc
      return spread
    end # method
   
    def self.get_game_times_bovada(doc)
      times = []
      temp_date = [] # start empty, assume first row will provide date
      temp_month = []
      temp_day = []
      
      doc.css('#event-schedule > div').each do |time|
        
        if time.text.gsub(/\s+/, "") =~ /^[ADFJMNOS][A-Z]+[1-9][0-9]?/ # date
          temp_date = time.text.gsub(/\s+/, "")[/^[ADFJMNOS][A-Z]+[1-9][0-9]?/]
          temp_month = DateTime.strptime(temp_date[/[A-Z]*/].downcase.capitalize, '%B' )
          temp_day = DateTime.strptime(temp_date[/[0-9]+/], '%d')
        
        elsif time.text.gsub(/\s+/, "") =~ /^[0-9]+:[0-9][0-9][ap]/
          temp_hour = time.text.gsub(/\s+/, "")[/[0-9]+:/]
          temp_hour = temp_hour[0..-2]
          temp_min = time.text.gsub(/\s+/, "")[/:[0-9]+/]
          temp_min = temp_min[1..-1]
          
          if Integer(temp_hour) < 12
            temp_hour = (Integer(temp_hour) + 12).to_s
          end
          
          times << DateTime.new(DateTime.now.in_time_zone("Eastern Time (US & Canada)").year,
                                temp_month.month,
                                temp_day.day,
                                Integer(temp_hour),
                                Integer(temp_min), 0, get_offset )
        end # if checking for game time or date
       
       end # do, looping through css identifiers
       return times
    end # method
    
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
        
        times << DateTime.new(DateTime.now.in_time_zone("Eastern Time (US & Canada)").year,
                              DateTime.now.in_time_zone("Eastern Time (US & Canada)").month,
                              DateTime.now.in_time_zone("Eastern Time (US & Canada)").day,
                              Integer(temp_hour),
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
    
    def self.get_away_teams(games)
      teams = []
      games.each do |game|
        teams << full_team_name_NBA(game[/[a-zA-Z]+(\s[A-Z])?[a-zA-Z]*/])
      end
      return teams
    end
  
    def self.get_home_teams(games)
      teams = []
      games.each do |game|
        temp_team = game[/at\s[a-zA-Z]+\s?[a-zA-Z]*/]
        teams << full_team_name_NBA(temp_team[3..-1])
      end
      return teams
    end
  
 #   def self.get_over_unders(lines)
 #     over_unders = []
 #     lines.each do |line|
 #       over_unders << line[/[0-9]+\.[0-9]+/]
 #     end
 #     return over_unders
 #   end
    
 #   def self.get_spreads(lines)
 #     spreads = []
 #     lines.each do |line|
 #       spreads << line[/[\-\+][0-9]+\.[0-9]+/]
 #     end
 #     return spreads
 #   end
 
    def self.get_offset
      Rational(Time.now.utc.in_time_zone("Eastern Time (US & Canada)").utc_offset, 60*60*24)
    end
    
    def self.get_home_teams2(doc)
      teams = []
      doc.css(".home .team-name a").each do |t|
        teams << full_team_name_NFL(t.children.text)
      end
      return teams
    end
    
    def self.get_away_teams2(doc)
      teams = []
      doc.css(".visitor .team-name a").each do |t|
        teams << full_team_name_NFL(t.children.text)
      end
      return teams
    end
    
    def self.get_scores_home(doc)
      scores = []
      doc.css(".home .final").each do |s|
        scores << s.text.to_f
      end
      return scores
    end
    
    def self.get_scores_away(doc)
      scores = []
      doc.css(".visitor .final").each do |s|
        scores << s.children.text.to_f
      end
      return scores
    end
    
    def self.get_games(home_teams, away_teams)
      games = []
      yesterday = Time.now.utc.in_time_zone("Eastern Time (US & Canada)").ago(8*60*60)
      for i in 0..(home_teams.length-1)
        games << Game.where("home_team = ? AND
                             away_team = ? AND
                             game_time >  ? AND
                             game_time < ?", 
                             home_teams[i],
                             away_teams[i],
                             yesterday,
                             Time.now).last
      end
      return games
    end
    
    def self.update_game_scores(games, home_team_scores, away_team_scores, game_status)
      for i in 0..(games.length - 1)
        unless games[i].nil?
          game = Game.find(games[i].id)
          game.update_attribute(:home_score, home_team_scores[i])
          game.update_attribute(:away_score, away_team_scores[i])
          game.update_attribute(:game_status, game_status[i])
          game.save!

          if game_status[i] == "Final"
            Bet.update_bet_for_game( game )
          end # if
        end # unless
      end # for
    end # method
    
    def self.get_game_status(doc)
      status = []
      doc.css(".game-status p").each do |s|
        temp_status = s.text[/[a-zA-Z]+/] == "Final" ? "Final" : "In Progress"
        status << temp_status
      end
      return status
    end
    
    def self.full_team_name_NFL ( team )
      case team
      # AFC East
      when "Bills"        then return "Buffalo Bills"
      when "Dolphins"     then return "Miami Dolphins"
      when "Patriots"     then return "New England Patriots"
      when "Jets"         then return "New York Jets"
      # AFC West
      when "Broncos"      then return "Denver Broncos"
      when "Chiefs"       then return "Kansas City Chiefs"
      when "Raiders"      then return "Oakland Raiders"
      when "Chargers"     then return "San Diego Chargers"
      # AFC North
      when "Ravens"       then return "Baltimore Ravens"
      when "Bengals"      then return "Cincinnati Bengals"
      when "Browns"       then return "Cleveland Browns"
      when "Steelers"     then return "Pittsburgh Steelers"
      # AFC South
      when "Texans"       then return "Houston Texans"
      when "Colts"        then return "Indianapolis Colts"
      when "Jaguars"      then return "Jacksonville Jaguars"
      when "Titans"       then return "Tennessee Titans"
      # NFC East
      when "Cowboys"      then return "Dallas Cowboys"
      when "Giants"       then return "New York Giants"
      when "Eagles"       then return "Philadelphia Eagles"
      when "Redskins"     then return "Washington Redskins"
      # NFC West
      when "Cardinals"    then return "Arizona Cardinals"
      when "49ers"        then return "San Francisco 49ers"
      when "Seahawks"     then return "Seattle Seahawks"
      when "Rams"         then return "St. Louis Rams"
      # NFC North
      when "Bears"        then return "Chicago Bears"
      when "Lions"        then return "Detroit Lions"
      when "Packers"      then return "Green Bay Packers"
      when "Vikings"      then return "Minnesota Vikings"
      # NFC South
      when "Falcons"      then return "Atlanta Falcons"
      when "Panthers"     then return "Carolina Panthers"
      when "Saints"       then return "New Orleans Saints"
      when "Buccaneers"   then return "Tampa Bay Buccaneers"
      end
    end
    
 #   def self.full_team_name_MLB ( team )
 #     case team
 #     when "Baltimore"        then return "Baltimore Orioles"
 #     when "Orioles"          then return "Baltimore Orioles"
 #     when 'Red Sox'          then return 'Boston Red Sox'
 #     when 'Boston'           then return 'Boston Red Sox'
 #     when 'Yankees'          then return 'New York Yankees'
      #
 #     when 'Rays'             then return 'Tampa Bay Rays'
 #     when 'Tampa Bay'        then return 'Tampa Bay Rays'
 #     when 'Blue Jays'        then return 'Toronto Blue Jays'
 #     when 'Toronto'          then return 'Toronto Blue Jays'
 #     when 'Braves'           then return 'Atlanta Braves'
 #     when 'Atlanta'          then return 'Atlanta Braves'
 #     when 'Marlins'          then return 'Florida Marlins'
 #     when 'Miami'            then return 'Florida Marlins'
 #     when 'Mets'             then return 'New York Mets'
      #
 #     when 'Phillies'         then return 'Philadelphia Phillies'
 #     when 'Philadelphia'     then return 'Philadelphia Phillies'
 #     when 'Nationals'        then return 'Washington Nationals'
 #     when 'Washington'       then return 'Washington Nationals'
 #     when 'White Sox'        then return 'Chicago White Sox'
      #
 #     when 'Indians'          then return 'Cleveland Indians'
 #     when 'Cleveland'        then return 'Cleveland Indians'
 #     when 'Tigers'           then return 'Detroit Tigers'
 #     when 'Detroit'          then return 'Detroit Tigers'
 #     when 'Royals'           then return 'Kansas City Royals'
 #     when 'Kansas City'      then return 'Kansas City Royals'
 #     when 'Twins'            then return 'Minnesota Twins'
 #     when 'Minnesota'        then return 'Minnesota Twins'
 #     when 'Cubs'             then return 'Chicago Cubs'
      #
  #    when 'Reds'             then return 'Cincinnati Reds'
  #    when 'Astros'           then return 'Houston Astros'
  #    when 'Brewers'          then return 'Milwaukee Brewers'
  #    when 'Milwaukee'        then return 'Milwaukee Brewers'
  #    when 'Pirates'          then return 'Pittsburgh Pirates'
  #    when 'Pittsburgh'       then return 'Pittsburgh Pirates'
  #    when 'Cardinals'        then return 'St. Louis Cardinals'
  #    when 'St. Louis'        then return 'St. Louis Cardinals'
  #    when 'Angels'           then return 'Los Angeles Angels'
      #
  #    when 'Athletics'        then return 'Oakland Athletics'
  #    when 'Oakland'          then return 'Oakland Athletics'
  #    when 'Mariners'         then return 'Seattle Mariners'
  #    when 'Seattle'          then return 'Seattle Mariners'
  #    when 'Rangers'          then return 'Texas Rangers'
  #    when 'Texas'            then return 'Texas Rangers'
  #    when 'Diamondbacks'     then return 'Arizona Diamondbacks'
  #    when 'Arizona'          then return 'Arizona Diamondbacks'
  #    when 'Rockies'          then return 'Colorado Rockies'
  #    when 'Colorado'         then return 'Colorado Rockies'
  #    when 'Dodgers'          then return 'Los Angeles Dodgers'
      #
  #    when 'Padres'           then return 'San Diego Padres'
  #    when 'San Diego'        then return 'San Diego Padres'
  #    when 'Giants'           then return 'San Francisco Giants'
  #    when 'San Francisco'    then return 'San Francisco Giants'
  #    end
  #  end
    
  #  def self.full_team_name_NBA( team )
  #    case team
  #      when "Atlanta"       then return "Atlanta Hawks"
  #      when "Hawks"         then return "Atlanta Hawks"
  #      when "Boston"        then return "Boston Celtics"
  #      when "Celtics"       then return "Boston Celtics"
  #      when "Charlotte"     then return "Charlotte Bobcats"
  #      when "Bobcats"       then return "Charlotte Bobcats"
  #      when "Chicago"       then return "Chicago Bulls"
  #      when "Bulls"         then return "Chicago Bulls"
  #      when "Cleveland"     then return "Cleveland Cavaliers"
  #      when "Cavaliers"     then return "Cleveland Cavaliers"
  #      when "Dallas"        then return "Dallas Mavericks"
  #      when "Mavericks"     then return "Dallas Mavericks"
  #      when "Denver"        then return "Denver Nuggets"
  #      when "Nuggets"       then return "Denver Nuggets" 
  #      when "Detroit"       then return "Detroit Pistons"
  #      when "Pistons"       then return "Detroit Pistons"
  #      when "Golden State"  then return "Golden State Warriors"
  #      when "Warriors"      then return "Golden State Warriors"
  #      when "Houston"       then return "Houston Rockets"
  #      when "Rockets"       then return "Houston Rockets"
  #      when "Indiana"       then return "Indiana Pacers"
  #      when "Pacers"        then return "Indiana Pacers"
  #      when "LA Clippers"   then return "Los Angeles Clippers"
  #      when "Clippers"      then return "Los Angeles Clippers"
  #      when "LA Lakers"     then return "Los Angeles Lakers"
  #      when "Lakers"        then return "Los Angeles Lakers"
  #      when "Memphis"       then return "Memphis Grizzlies"
  #      when "Grizzlies"     then return "Memphis Grizzlies"
  #      when "Miami"         then return "Miami Heat"
  #      when "Heat"          then return "Miami Heat"
  #      when "Milwaukee"     then return "Milwaukee Bucks"
  #      when "Bucks"         then return "Milwaukee Bucks"
  #      when "Minnesota"     then return "Minnesota Timberwolves"
  #      when "Timberwolves"  then return "Minnesota Timberwolves"
  #      when "New Jersey"    then return "New Jersey Nets"
  #      when "Nets"          then return "New Jersey Nets"
  #      when "New Orleans"   then return "New Orleans Hornets"
  #      when "Hornets"       then return "New Orleans Hornets"
  #      when "New York"      then return "New York Knicks"
  #      when "NY Knicks"     then return "New York Knicks"
  #      when "Knicks"        then return "New York Knicks"
  #      when "Oklahoma City" then return "Oklahoma City Thunder"
  #      when "Thunder"       then return "Oklahoma City Thunder"
  #      when "Orlando"       then return "Orlando Magic"
  #      when "Magic"         then return "Orlando Magic"
  #      when "Philadelphia"  then return "Philadelphia 76ers"
  #      when "76ers"         then return "Philadelphia 76ers"
  #      when "Phoenix"       then return "Phoenix Suns"
  #      when "Suns"          then return "Phoenix Suns"
  #      when "Portland"      then return "Portland Trail Blazers"
  #      when "Trail Blazers" then return "Portland Trail Blazers"
  #      when "Sacramento"    then return "Sacramento Kings"
  #      when "Kings"         then return "Sacramento Kings"
  #      when "San Antonio"   then return "San Antonio Spurs"
  #      when "Spurs"         then return "San Antonio Spurs"
  #      when "Toronto"       then return "Toronto Raptors"
  #      when "Raptors"       then return "Toronto Raptors"
  #      when "Utah"          then return "Utah Jazz"
  #      when "Jazz"          then return "Utah Jazz"
  #      when "Washington"    then return "Washington Wizards"
 #       when "Wizards"       then return "Washington Wizards"
 #     end
 #   end

end
