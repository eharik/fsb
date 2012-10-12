require 'digest'
class User < ActiveRecord::Base
  has_many :bets, :dependent => :destroy
  has_many :leagues, :through => :bets
  has_many :memberships, :dependent => :destroy
  has_many :leagues, :through => :memberships
  has_attached_file :photo, {
                    :styles => {:small => "160x225>", :thumb => "50x50>"},
                    }.merge(PAPERCLIP_STORAGE_OPTIONS)
  
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
    Membership.where(:league_id => league.id, :user_id => id).first.record.to_s
  end
  
  def buy_backs (league)
    bb = Membership.where(:league_id => league.id, :user_id => id).first.buy_backs.to_f
    return sprintf("%2.0f", bb)
  end
  
  def has_room_for_locks?( league )
    locks_allowed = 5
    week_number = league.what_week
    locks_this_week = this_weeks_locks( league, self.id, week_number ).length
    if locks_this_week < locks_allowed
      return true
    else
      return false
    end
  end
  
  def unique_lock?( bet )
    bets = Bet.where( :user_id => self.id, :game_id => bet.game_id, :bet_type => bet.bet_type, :lock => bet.lock )
    if bets.empty?
      return true
    else
      return false
    end
  end
  
  def buy_in (league)
    bi = Membership.where(:league_id => league.id, :user_id => id).first.buy_in.to_f
    return sprintf("%2.0f", bi)
  end
  
  def this_weeks_locks( league, current_user_id, week )
      week_number = week
      week_start_date = league.start_date + (week_number-1).weeks
			next_week = league.start_date + (week_number).weeks
			puts week_start_date
			puts next_week
      all_locks = Bet.where( :user_id => self.id,
                             :league_id => league.id,
                             :lock => true )
      locks_this_week = [];
      # if looking at your own locks then show all
      if self.id == current_user_id
        all_locks.each do |lock|
					game = Game.find(lock.game_id)
					game_time = Time.parse(game.game_time + " UTC")
          if game_time > week_start_date and game_time < next_week
            locks_this_week << lock
          end # if
        end # all _locks_loop
      # else, only show games in the past
      else
        all_locks.each do |lock|
        game = Game.find(lock.game_id)
        game_time = Time.parse(game.game_time + " UTC")
          if game_time > week_start_date and game_time.past?
            locks_this_week << lock
          end # if
        end # all _locks_loop           
      end

			puts locks_this_week.length
      return locks_this_week
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
    
    def get_number_of_locks (league, week_number)
      week_start_date = league.start_date + (week_number-1).weeks

      all_locks = Bet.where( :user_id => self.id, :league_id => league.id, :lock => true )
      locks_this_week = [];
      all_locks.each do |lock|
        game = Game.find(lock.game_id)
        game_time = Time.parse(game.game_time + " UTC")
        if game_time > week_start_date
          locks_this_week << lock
        end # if
      end # all _locks_loop
      return locks_this_week.length
    end
    
end
