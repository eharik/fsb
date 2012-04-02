require 'digest'
class League < ActiveRecord::Base
  has_many :bets, :dependent => :destroy
  has_many :users, :through => :bets
  has_many :memberships, :dependent => :destroy
  has_many :users, :through => :memberships
  
  serialize :league_settings
  attr_accessor   :password
  attr_accessible :name, :password, :password_confirmation, :manager
  
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
  
  def rank
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
