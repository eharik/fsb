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
  
  validates :name,     :presence     => true,
                       :uniqueness   => { :case_sensitive => false }
  validates :password, :presence     => true,
                       :confirmation => true
  
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
  
  def schedule_games
    # team number '-1' represents a bye week and should be parsed as such
    puts "-----------------------"
    puts "--Scheduling Matchups--"
    puts "-----------------------"
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
    days_since_start = (DateTime.now.utc - self.start_date.to_datetime.utc)
    weeks_since_start = 1
    if days_since_start > 0
      weeks_since_start = days_since_start.ceil / 7 + 1 # first week is '1' not '0'
    end

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
        puts "Week #{week}: #{team_user_ids[m_up-1]} vs #{team_user_ids[-m_up]}"
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
