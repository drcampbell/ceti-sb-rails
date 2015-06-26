Rails.application.routes.draw do
  mount Upmin::Engine => '/admin'

  devise_for :users, :controllers => { registrations: 'registrations', sessions: "sessions" }

  devise_scope :user do
    post    '/users/sign_up'  =>  'registrations#create'
    post    'users/sign_in'   =>  'sessions#create'
    delete    'users/sign_out'  =>  'sessions#destroy'
    post    'account'         => 'registrations#edit'
    get     'profile'         => 'registrations#profile'
  end

  namespace :api do
#    namespace :v1 do
    devise_scope :user do
      post 'users/sign_in' => 'sessions#create'
      delete    'users/sign_out'  =>  'sessions#destroy'
    end
    post 'events/create' => 'events#create'
    resources :sessions
    resources :users
    resources :schools
    resources :events
#  end
  end

  resources :users
  resources :schools
  resources :events
  resources :claims
  resources :locations
  resources :static_pages

  root to: 'static_pages#home'
  get    'choose' => 'schools#choose'
  get    'help'    => 'static_pages#help'
  get    'about'   => 'static_pages#about'
  get    'contact' => 'static_pages#contact'
  get    'signin'  => 'static_pages#signin'
  get    'invalid_event'  => 'static_pages#invalid_event'
  get     'message' => 'users#message'
  get 'tags/:tag',  to: 'events#index', as: :tag
  get 'users/:tag',  to: 'users#index'
  post 'make_mine', to: 'schools#make_mine'
  #get     'users/edit'      => 'registrations#edit'

  match 'claims/:id/teacher_confirm' => 'claims#teacher_confirm', :via => [:post], :as => 'teacher_confirm_claim'
  match 'claims/:id/speaker_confirm' => 'claims#speaker_confirm', :via => [:post], :as => 'speaker_confirm_claim'
  match 'events/claim_event' => 'events#claim_event', :via => [:post], :as => 'claim_event'
  match 'schools/claim_school' => 'schools#claim_school', :via => [:post], :as => 'claim_school'
  #match '/contacts', to: 'contacts#new',
  #resources "contacts", only: [:new, :create]
end
