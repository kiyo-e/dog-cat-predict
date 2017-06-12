Rails.application.routes.draw do

  post :predict, to: "top#predict", as: :predict
  root to: "top#index"
end
