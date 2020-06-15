# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get '/issues_board', :to => 'issues_board#index', :as => 'issues_board'
get '/projects/:project_id/issues_board', :to => 'issues_board#index', :as => 'project_issues_board'
put '/move_issue_card', :to => 'issues_board#move_issue_card', :as => 'move_issue_card'
