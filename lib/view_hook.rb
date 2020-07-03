module IssuesPanel
  class ViewHook < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context={})
      html = +''
      if (context[:controller] && context[:controller].is_a?(QueriesController)) &&
        (context[:request] && context[:request].try(:params).is_a?(Hash) && context[:request].params['issues_panel'])
        js = <<~JS
          $(document).ready(function(){
            $('form#query-form').append('#{hidden_field_tag('issues_panel', '1')}');
            $('p.block_columns').remove();
            $('p.totable_columns').remove();
          });
        JS
        html << javascript_tag(js)
      end
      return html
    end
  end
end
