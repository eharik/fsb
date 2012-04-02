module UsersHelper
  
  def gravatar_for(user, options = { :size => 50 } )
    gravatar_image_tag(user.email.downcase, :alt => user.name,
                                            :class => 'gravatar',
                                            :gravatar => options )
  end
  
  def get_number_of_leagues
    "0 leagues"
  end
  
  def get_number_of_managed_leagues
    "10 leagues"
  end
  
  def get_leagues
    league_membership = []
    
  end
end
