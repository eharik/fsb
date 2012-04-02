Fsb::Application.routes.draw do
  resources :users
  resources :leagues
  resources :sessions, :only => [:new, :create, :destroy]
  resources :memberships
  resources :bets, :only => [:new, :create]
  
  match '/signup',              :to => 'users#new'
  match '/signin',              :to => 'sessions#new'
  match '/signout',             :to => 'sessions#destroy'
  match '/join',                :to => 'memberships#new'
  match '/new_league',          :to => 'leagues#new'
  match '/rules',               :to => 'leagues#rules'
  match '/leagues_all',         :to => 'leagues#index'
  match '/leagues/add_bet',     :to => 'bets#new'
  match '/bets/submitted',       :to => 'bets#submitted'
  
  root :to => 'sessions#new'

end
