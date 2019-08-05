Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

	root 'gitdiff#index'

	get '/showdiff' => 'gitdiff#showdiff'

	post '/import' => 'gitdiff#import'
	post '/showdiff' => 'gitdiff#showdiff'
	post '/test' => 'gitdiff#test', as: 'test'
end
