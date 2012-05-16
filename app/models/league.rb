require 'digest'
require 'ostruct'
class League < ActiveRecord::Base
  has_many :bets, :dependent => :destroy
  has_many :users, :through => :bets
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  has_attached_file :photo,
                    :styles => {:small => "160x225>", :thumb => "50x50"},
                    :storage => :s3,
                    :bucket => ENV['fsb'],
                    #:default_url => '/photos/league/missing_:style.png',
                    :s3_credentials => {
                      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
                      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
                    }
  
  serialize :league_settings, Hash
  attr_accessor   :password
  attr_accessible :name, :password, :password_confirmation, :manager, :photo, :league_settings
  
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
  
  def self.scheduler_test
    puts "**********scheduler_running --> #{Time.now} **************"
  end
  
 # def self.update_bets
 #   puts "**********updating_bets**************"
 #   League.all.each do |l|
 #     l.memberships.each do |m|
 #       user = User.find(m.user_id)
 #       all_bets = Bet.all_bets(l, user)
 #       all_bets.each do |b|
 #         unless (b.won == true || b.won == false)
 #           m.update_credits_for_bet( b )
 #         end
 #       end
 #     end
 #   end
 # end
  
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
