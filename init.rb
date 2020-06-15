require 'redmine'
require 'queries_controller_patch'
require 'view_hook'

Redmine::Plugin.register :redmine_issues_board do
  name 'Redmine Issues Board plugin'
  author 'Takenori Takaki'
  description 'A plugin for Redmine to display issues by statuses and change it\'s status by DnD.'
  version '0.0.1'
  url 'http://github.com/takenory/redmine_issues_board'
  author_url 'http://github.com/takenory'

  # permission setting
  project_module :issues_board do
    permission :use_issues_board, { :issues_board => [:index, :change_issue_status] }, :public => true, :require => :member
  end

  # menu setting
  menu :project_menu, :issues_board, { :controller => 'issues_board', :action => 'index' }, :caption => :label_issues_board_plural, :after => :issues, :param => :project_id
  menu :application_menu, :issues_board, { :controller => 'issues_board', :action => 'index' }, :caption => :label_issues_board_plural, :after => :issues
end
