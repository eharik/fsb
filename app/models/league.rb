require 'digest'
require 'ostruct'
class League < ActiveRecord::Base
  has_many :bets, :dependent => :destroy
  has_many :users, :through => :bets
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  has_many :matchups, :dependent => :destroy
  has_attached_file :photo,
                    :styles => {:small => "160x120>", :thumb => "50x40"},
                    :storage => :s3,
                    :bucket => ENV['fsb'],
                    :default_url => '/:attachment/:class/missing_:style.png',
                    :s3_credentials => {
                      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
                      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
                    }
  
  serialize :league_settings, Hash
  serialize  :schedule, OpenStruct
  attr_accessor   :password
  attr_accessible :name, :password, :password_confirmation,
                  :manager, :photo, :league_settings, :start_date, :number_of_weeks
  
  validates :name,            :presence     => true,
                              :uniqueness   => { :case_sensitive => false }
  validates :password,        :presence     => true,
                              :confirmation => true
  validates :number_of_weeks, :numericality => { :greater_than => 0 }
  
  before_save :encrypt_password
  
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)  
  end
  
  def self.authenticate(league_name, submitted_password)
    league = find_by_name(league_name)
    return nil     if league.nil?
    return league  if league.has_password?(submitted_password)
  end
  
  def self.authenticate_with_salt(id, cookie_salt)
    league = find_by_id(id)
    (league && league.salt == cookie_salt) ? league : nil
  end
  
  def set_start_date
    # assumes league manager entered start date so it exists already
    # updates it to be the Tuesday before at 6AM EST.
    temp_start = self.start_date
    
    #convert to EST
    temp_start = temp_start.in_time_zone('America/New_York')
    #set hour to 6AM
    temp_start = temp_start.change(:hour => 6 )
    #roll back a day until day is Tuesday
    until temp_start.tuesday?
      temp_start = temp_start.yesterday
    end
    
    self.start_date = temp_start
    
  end
  
  def schedule_games
    # team number '-1' represents a bye week and should be parsed as such

    # if odd number of teams add 'bye week'
    team_user_ids = []
    self.users.each do |t|
      team_user_ids << t.id
    end
    team_user_ids.sort
    if team_user_ids.length.odd?
      team_user_ids << -1
    end
    
    # figure out what week of the league it is
    weeks_since_start = self.what_week

    # get matchups
    m = self.matchups
    
    # delete matchups for this week forward
    unless m.nil?
      m.each do |m_up|
        if m_up.week >= weeks_since_start
          m_up.delete
        end
      end
    end

    # reset schedule from that week on via round robin algorithm
    for week in weeks_since_start..(self.number_of_weeks)
      
      # replace with new matchups
      for m_up in 1..(team_user_ids.length/2)
        #puts "Week #{week}: #{team_user_ids[m_up-1]} vs #{team_user_ids[-m_up]}"
        new_matchup = Matchup.new
        new_matchup.league_id       = self.id
        new_matchup.week            = week;
        new_matchup.away_team_id    = team_user_ids[m_up-1]
        new_matchup.home_team_id    = team_user_ids[-m_up]
        new_matchup.away_team_score = 0
        new_matchup.home_team_score = 0
        new_matchup.save
      end
      
      #rotate
      temp_array = team_user_ids[1..-1]
      for index in 0..(temp_array.length-1)
        team_user_ids[index+1] = temp_array[index-1]
      end
      
    end
    
  end
  
  # -------- returns the given week in a league
  def what_week
    days_since_start = (DateTime.now.utc - self.start_date.to_datetime.utc)
    weeks_since_start = 1
    if days_since_start > 0
      weeks_since_start = (days_since_start.to_f / 7.0).floor + 1 # first week is '1' not '0'
    end

    return weeks_since_start
  end
  
  # ---------- returns a formatted string for matchup page for matchup header
  # takes a week number and user and returns appropriate string
  def matchup_string( user_id, week_number )
    
    if (user_id == -1) || (self.opponent( user_id, week_number ) == -1)
      return "BYE WEEK"
    else
      opponent_user = User.find( self.opponent( user_id, week_number ) )
      opponent_score = self.score( opponent_user.id, week_number )
      user = User.find( user_id )
      user_score = self.score( user_id, week_number )
      if self.home?( user_id, week_number )
        return "#{opponent_user.name} (#{opponent_score})     vs     #{user.name} (#{user_score})"
      else
        return "#{user.name} (#{user_score})     vs     #{opponent_user.name} (#{opponent_score})"
      end  # if for checking home team
    end # if for -1 for bye week
  end
  
  # ---------- returns true if given user on given week is the home team
  def home?( user_id, week_number )
    m = Matchup.where( :league_id    => self.id,
                       :home_team_id => user_id,
                       :week         => week_number).first
    if m.nil?
      return false
    else
      return true
    end
  end
  
  # ---------- returns the id of an opponent given one user id and a week, or -1 if on bye
  def opponent( user_id, week_number )
    m = Matchup.where( :league_id    => self.id,
                       :home_team_id => user_id,
                       :week         => week_number).first
    unless m.nil?
      opponent_id = m.away_team_id
    end
    
    if m.nil?
      m = Matchup.where( :league_id    => self.id,
                         :away_team_id => user_id,
                         :week         => week_number).first
      opponent_id = m.home_team_id
    end
    
    return opponent_id
    
  end
  
  # ------ returns the number of correct lock picks for a user and week ------#
  # ------ only correct if game is final -------------------------------------#
  def score( user_id, week_number )
    # get matchup
    matchup = Matchup.user_matchup( self.id, user_id, week_number )
    # if home team, return home team score
    if matchup.home_team?( user_id )
      return matchup.home_team_score
    else
    # if away team, return away team score
      return matchup.away_team_score
    end
  end
  
  # ------ Updates the League Record at the end of the week ------ #
  # ------ Allocates credits to winner, subtracts from loser ----- #
  def self.update_matchups
    # if it's tuesday... (heroku can't run weekly, so have to do daily)
    puts "----->>>  In Update Matchup Function <<<------"
    if DateTime.now.wednesday?
      puts "**********updating_matchups --> #{Time.now} **************"
      League.all.each do |l|
        # get matchups
        last_week = l.what_week - 1
        matchups = Matchup.league_matchups( l.id, last_week )

        matchups.each do |m|
          Membership.update_credits_for_matchup( m, l.league_settings["h2h_bet"] )
        end
      end # each league
      
    end # if
    puts "------<<< Leaving Update Matchup Function >>>------"
  end
  
  private
  
    def encrypt_password
      self.salt = make_salt if new_record?
      self.encrypted_password = encrypt(password)
    end
    
    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end
    
    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end
    
    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end
    
end
