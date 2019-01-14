Rails.application.routes.draw do
  get 'home/ticker'
  get 'home/live'
  get 'home/sse'
  get 'home/chat'
  root 'home#index'

  mount ActionCable.server => "/cable"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
