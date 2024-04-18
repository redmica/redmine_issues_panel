# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/issues_panel', :to => 'issues_panel#index', :as => 'issues_panel'
get '/projects/:project_id/issues_panel', :to => 'issues_panel#index', :as => 'project_issues_panel'
get '/show_issue_description', :to => 'issues_panel#show_issue_description', :as => 'show_issue_description'
put '/move_issue_card', :to => 'issues_panel#move_issue_card', :as => 'move_issue_card'
match '/new_issue_card', :to => 'issues_panel#new_issue_card', :as => 'new_issue_card', :via => [:get, :post]
