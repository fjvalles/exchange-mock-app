Rails.application.routes.draw do
  # Health check for Render / load balancers
  get "/up", to: proc { [200, {}, ["OK"]] }

  # Swagger UI — served as static HTML
  get "/api-docs", to: redirect("/api-docs.html")

  namespace :api do
    namespace :v1 do
      post "auth/login",  to: "auth#login"
      post "auth/logout", to: "auth#logout"

      resources :balances,  only: [:index]
      resources :prices,    only: [:index]
      resources :exchanges, only: [:index, :show, :create]
    end
  end
end
