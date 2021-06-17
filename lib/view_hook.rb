module IssuesPanel
  class ViewHook < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context={})
      query = context[:controller].instance_variable_get(:'@query')
      html = +''
      if (context[:controller] && context[:controller].is_a?(QueriesController)) &&
        (context[:request] && context[:request].try(:params).is_a?(Hash) && context[:request].params['issues_panel'])
        js = <<~JS
          $(document).ready(function(){
            var selector = '#{select_tag('query[issues_num_per_row]', options_for_select([1, 2, 3], (query && query.issues_num_per_row)).gsub("\n",'').html_safe)}';
            $('form#query-form').append('#{hidden_field_tag('issues_panel', '1')}');
            $('p.block_columns').remove();
            $('p.totable_columns').remove();
            $('p#group_by').after('<p id="issues_num_per_row"><label for="query_issues_num_per_row">#{l(:field_issues_num_per_row)}</label>' + selector + '</p>');
          });
        JS
        html << javascript_tag(js)
      end
      return html
    end
  end
end
