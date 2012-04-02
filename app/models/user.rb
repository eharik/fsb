require 'digest'
class User < ActiveRecord::Base
  has_many :bets
  has_many :leagues, :through => :bets
  has_many :memberships
  has_many :leagues, :through => :memberships
  has_attached_file :photo, :styles => {:small => "160x225>"}
  
  attr_accessor   :password
  attr_accessible :name, :email, :password, :password_confirmation, :photo
    
  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validates :name,     :presence     => true,
                       :length       => { :maximum => 50 }
  validates :email,    :presence     => true,
                       :format       => { :with => email_regex },
                       :uniqueness   => { :case_sensitive => false }
  validates :password, :presence     => true,
                       :confirmation => true,
                       :length       => { :within => 6..40 }
                       
  before_save :encrypt_password
  
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end
  
  def self.authenticate(email, submitted_password)
    user = find_by_email(email)
    return nil   if user.nil?
    return user  if user.has_password?(submitted_password)
  end
  
  def self.authenticate_with_salt(id, cookie_salt)
    user = find_by_id(id)
    (user && user.salt == cookie_salt) ? user : nil
  end
  
  def rank (league)
    ms = league.memberships
    num_members = ms.count
    ms.sort! { |a,b| a.credits.week1 <=> b.credits.week1 }
    ms.reverse!
    rank_index = ms.index{ |a| a.user_id == id } + 1
    sprintf( "%10d/%d", rank_index, num_members)
  end
  
  def record (league)
  end
  
  def buy_backs (league)
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
