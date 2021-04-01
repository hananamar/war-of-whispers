Rails.application.routes.draw do
  resources :games

  get 'help' => 'pages#help', as: :help_page

  root to: 'pages#home'
end
