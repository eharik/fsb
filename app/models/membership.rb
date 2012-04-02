class Membership < ActiveRecord::Base
  require 'ostruct'
  belongs_to :user
  belongs_to :league
  
  serialize  :credits, OpenStruct
  
  attr_accessor :league_name, :league_password
  
end
