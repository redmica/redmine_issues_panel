require 'redmine'
require 'queries_controller_patch'
require 'view_hook'
require 'issue_query_patch'

Redmine::Plugin.register :redmine_issues_panel do
  name 'Redmine Issues Panel plugin'
  author 'Takenori Takaki (Far End Technologies)'
  description 'A plugin for Redmine to display issues by statuses and change it\'s status by DnD.'
  requires_redmine version_or_higher: '4.1'
  version '0.0.2'
  url 'https://github.com/redmica/redmine_issues_panel'
  author_url 'https://hosting.redmine.jp/'

  # permission setting
  project_module :issues_panel do
    permission :use_issues_panel, { :issues_panel => [:index, :move_issue_card, :new_issue_card] }, :public => true, :require => :member
  end

  # menu setting
  menu :project_menu, :issues_panel, { :controller => 'issues_panel', :action => 'index' }, :caption => :label_issues_panel_plural, :after => :issues, :param => :project_id
  menu :application_menu, :issues_panel, { :controller => 'issues_panel', :action => 'index' }, :caption => :label_issues_panel_plural, :after => :issues, :if => proc { User.current.allowed_to?(:view_issues, nil, :global => true) && EnabledModule.exists?(:project => Project.visible, :name => :issues_panel) }
end
