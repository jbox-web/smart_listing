# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users do
    collection do
      get 'sortable'
      get 'searchable'
    end
  end

  namespace :admin do
    resources :users do
      member do
        put 'change_name'
      end
    end
  end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'users#index'
end
