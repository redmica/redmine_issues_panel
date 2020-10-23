module IssuesPanelHelper

  def _project_issues_panel_path(project, *args)
    if project
      project_issues_panel_path(project, *args)
    else
      issues_panel_path(*args)
    end
  end
end
