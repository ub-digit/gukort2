Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :card_messages
  resources :employee_messages
  resources :student_messages
  resources :student_participation_messages
  resources :user_messages
end
