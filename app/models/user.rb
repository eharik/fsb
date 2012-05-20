require 'digest'
class User < ActiveRecord::Base
  has_many :bets
  has_many :leagues, :through => :bets
  has_many :memberships
  has_many :leagues, :through => :memberships
  has_attached_file :photo,
                    :styles => {:small => "160x225>", :thumb => "50x50>"},
                    :storage => :s3,
                    :bucket => ENV['fsb'],
                    :default_url => '/:attachment/:class/missing_:style.png',
                    :s3_credentials => {
                      :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
                      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
                    }
  
  attr_accessor   :password, :updating_password
  attr_accessible :name, :email, :password, :password_confirmation, :photo
    
  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validates :name,     :presence     => true,
                       :length       => { :maximum => 50 }
  validates :email,    :presence     => true,
                       :format       => { :with => email_regex },
                       :uniqueness   => { :case_sensitive => false }
  validates :password, :unless       => :password_update?,
                       :presence     => true,
                       :confirmation => true,
                       :length       => { :within => 6..40 }
                       
  before_save :encrypt_password
  
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end
  
  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    self.updating_password = true
    save!
    UserMailer.password_reset(self).deliver
  end
  
  def password_update?
    updating_password
  end
  
  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
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
    ms.sort! { |a,b| a.credits.current.to_f <=> b.credits.current.to_f }
    ms.reverse!
    rank_index = ms.index{ |a| a.user_id == id } + 1
    sprintf( "%d/%d", rank_index, num_members)
  end
  
  def open_bets_risk (league)
    bets_to_sum = Bet.open_bets( league, self )
    total_risk = 0
    bets_to_sum.each do |b|
      total_risk += b.risk
    end
    total_risk
  end
  
  def credits (league)
    Membership.where(:league_id => league.id, :user_id => id).first.credits.current
  end
  
  def record (league)
    Membership.where(:league_id => league.id, :user_id => id).first.record
  end
  
  def buy_backs (league)
    Membership.where(:league_id => league.id, :user_id => id).first.buy_backs
  end
  
  def buy_in (league)
    Membership.where(:league_id => league.id, :user_id => id).first.buy_in
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
