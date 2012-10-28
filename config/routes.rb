Fsb::Application.routes.draw do
 
  resources :users #, :only => [:new, :edit, :show]
  resources :sessions, :only => [:new, :create, :destroy]
  resources :memberships
  resources :bets, :only => [:new, :create]
  resources :password_resets
  
  match '/signup',                          :to => 'users#new'
  match '/signin',                          :to => 'sessions#new'
  match '/signout',                         :to => 'sessions#destroy'
  match '/join',                            :to => 'memberships#new'
  match '/new_league',                      :to => 'leagues#new'
  match '/rules',                           :to => 'leagues#rules'
  match '/leagues_all',                     :to => 'leagues#index'
	match '/parlay_header',										:to => 'bets#parlay_header'
	match '/add_parlay',											:to => 'bets#new_parlay'
  match '/leagues/add_bet',                 :to => 'bets#new'
  match '/leagues/:id/matchups',            :to => 'leagues#matchups'
  match '/bets/submitted',                  :to => 'bets#submitted'
  match '/memberships/:id/unlock_buy_in',   :to => 'memberships#unlock_buy_in'
  match '/memberships/:id/unlock_buy_back', :to => 'memberships#unlock_buy_back'
  match '/memberships/:id/deploy_credits',  :to => 'memberships#deploy_credits'
  match '/super_user',                      :to => 'users#super_user'
  match '/super_user/:id/settings',         :to => 'users#su_settings'
  match '/super_user/:id/users',            :to => 'users#su_users'
  match '/super_user/credit_update',        :to => 'memberships#credit_update'
  
  resources :leagues do
    resources :bets, :only => [:index]
    resources :users, :only => [:index]
    resources :games, :only => [:index]
    member do
      get 'admin'
    end
  end 
  
  root :to => 'sessions#new'
  
end
