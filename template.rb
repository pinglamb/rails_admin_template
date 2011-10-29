def display(output, color = :green)
  say("         -  #{output}", color)
end

def ask_for(question, default = nil, color = :yellow)
  answer = ask("         -  #{question}", color)
  !default.nil? && answer.blank? ? default : answer
end

def rvm_run(command)
  run "rvm #{@rvm} exec #{command}"
end

display "Applying Rails Admin App Template"

display "Setup RVM"
current_ruby, current_gemset = `rvm current`.strip.split('@')
rvm_ruby = ask_for("Which RVM Ruby would you like to use? (#{current_ruby}) ", current_ruby)
rvm_gemset = ask_for("What name should the custom gemset have? (#{@app_name}) ", @app_name)
run "rvm #{rvm_ruby} gemset create #{rvm_gemset}"
@rvm = "#{rvm_ruby}@#{rvm_gemset}"
run "rvm use #{@rvm}"
create_file ".rvmrc", "rvm use #{@rvm}"
run "rvm rvmrc trust"
rvm_run "gem install bundler"
display "Using #{@rvm}"

display "Include RSpec, Cucumber, FactoryGirl and RailsAdmin in Gemfile"
append_to_file 'Gemfile', <<-RUBY

gem 'rails_admin', :git => 'git://github.com/sferik/rails_admin.git', :ref => '9664bcfbff25'
gem 'devise'

group :development, :test do
  gem 'rspec-rails'
  gem 'cucumber-rails'
  gem 'factory_girl_rails'
  gem 'ruby-debug19'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'minitest'
  gem 'launchy'
end
RUBY
rvm_run 'bundle install'

display "Install RSpec, Cucumber and RailsAdmin"
generate 'rspec:install'
generate 'cucumber:install'
generate 'rails_admin:install administrator admin'

display "Setup Devise"
inject_into_file 'config/environments/development.rb', :before => /^end$/, do
  %Q{\n  config.action_mailer.default_url_options = { :host => 'localhost:3000' }\n}
end

display "Setup RailsAdmin authentication model"
generate :controller, 'admin/sessions', '--skip-assets'
remove_file 'app/controllers/admin/sessions_controller.rb'
create_file 'app/controllers/admin/sessions_controller.rb', <<-RUBY
class Admin::SessionsController < Devise::SessionsController
  layout 'rails_admin/application'
  helper RailsAdmin::ApplicationHelper

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || rails_admin_path
  end

  def after_sign_out_path_for(resource)
    stored_location_for(resource) || new_administrator_session_path
  end
end
RUBY
create_file 'app/views/admin/sessions/new.html.erb', <<-RUBY
<% @page_name = 'Sign In' %>
<% @plugin_name = 'Admin Panel' %>
<% params[:action] = 'login' %>

<%= form_for(resource, :as => resource_name, :url => session_path(resource_name), :html => {:class => 'form'}) do |f| %>
  <fieldset>
    <legend>You need to login first</legend>
    <div class="clearfix field">
      <%= f.label :email %>
      <div class="input"><%= f.email_field :email, :class => 'string' %></div>
    </div>
    <div class="clearfix field">
      <%= f.label :password %>
      <div class="input"><%= f.password_field :password, :class => 'string' %></div>
    </div>
    <% if devise_mapping.rememberable? -%>
      <div class="clearfix field">
        <%= f.label :remember_me %>
        <div class="input"><%= f.check_box :remember_me %></div>
      </div>
    <% end -%>
  </fieldset>
  <div class="actions">
    <button class="btn primary" name="_submit" type="submit">
      Sign In
    </button>
  </div>
<% end %>
RUBY
create_file 'app/helpers/admin/base_helper.rb', <<-RUBY
module Admin::BaseHelper
  def dashboard_path
    rails_admin.dashboard_path
  end

  def _current_user
    instance_eval &RailsAdmin::Config.current_user_method
  end

  def _attr_accessible_role
    instance_eval &RailsAdmin::Config.attr_accessible_role
  end

  def _get_plugin_name
    @plugin_name_array ||= [RailsAdmin.config.main_app_name.is_a?(Proc) ? instance_eval(&RailsAdmin.config.main_app_name) : RailsAdmin.config.main_app_name].flatten
  end
end
RUBY
create_file 'app/views/layouts/rails_admin/_navigation.html.haml', <<-RUBY
- models = RailsAdmin::Config.visible_models.select { |model| authorized?(:index, model.abstract_model) }
- root_models = models.select { |model| model.parent == :root }

%ul#nav.navigation
  - if _current_user
    %li{:class => ("active" if @page_type == "dashboard")}
      = link_to(t("admin.dashboard.name"), dashboard_path)
    - root_models.each do |model|
      - children = [model] + models.select { |m| m.parent.to_s == model.abstract_model.model.to_s }
      - tab_titles = children.map { |child| child.abstract_model.pretty_name.downcase }
      - active = tab_titles.include? @page_type
      %li{:class => "\#{"active" if active} \#{"more" unless children.empty?}"}
        - if children.size == 1
          = link_to(model.label_plural, index_path(:model_name => model.abstract_model.to_param))
        - else
          = model.navigation_label ? t(model.navigation_label, :default => model.navigation_label) : model.label_plural
          %ul
            - children.each_with_index do |child, index|
              %li{:class => ("active" if @page_type == tab_titles[index])}
                = link_to(child.label_plural, index_path(:model_name => child.abstract_model.to_param))
  - else
    %li{:class => "active"}
      = link_to('Sign In', main_app.url_for(:action => 'new', :controller => 'admin/sessions'))
RUBY
create_file 'app/views/layouts/rails_admin/_secondary_navigation.html.haml', <<-RUBY
- if _current_user
  %li= link_to t('admin.dashboard.name'), dashboard_path
- if main_app_root_path = (main_app.root_path rescue false)
  %li= link_to t('home.name').capitalize, main_app_root_path
- if _current_user
  - if authorized?(:edit, _current_user.class, _current_user) && _current_user.respond_to?(:email)
    %li= link_to _current_user.email, edit_path(_current_user.class.name.underscore.pluralize, _current_user)
  - if defined?(Devise) && (devise_scope = request.env["warden"].config[:default_scope] rescue false) && (logout_path = main_app.send("destroy_\#{devise_scope}_session_path") rescue false)
    %li= link_to content_tag('span', t('admin.credentials.log_out'), :class => 'label important'), logout_path, :method => Devise.sign_out_via
  %li= image_tag "\#{(request.ssl? ? 'https://secure' : 'http://www')}.gravatar.com/avatar/\#{Digest::MD5.hexdigest _current_user.email}?s=30", :style => 'padding-top:5px'
RUBY
gsub_file 'app/models/administrator.rb', /,\s:registerable/, ''
gsub_file 'config/routes.rb', /\s\sdevise_for\s:administrators\n\n/, ''
inject_into_file 'config/routes.rb', :after => "Application.routes.draw do\n" do
<<-RUBY
  root :to => 'Admin::Sessions#new'
  devise_for :administrators, :path_prefix => '/admin', :controllers => {:sessions => "admin/sessions"}
RUBY
end

display "Prepare Database"
rake 'db:create'
rake 'db:migrate'
admin_email = ask_for("Default Administrator Email: (admin@example.com)", "admin@example.com", :yellow)
admin_password = ask_for("Default Adminstrator Password: (111111)", "111111", :yellow)
append_to_file 'db/seeds.rb', %Q{Administrator.create(:email => '#{admin_email}', :password => '#{admin_password}', :password_confirmation => '#{admin_password}') if Rails.env.development?\n}
rake 'db:seed'

display "Cleanup"
remove_file 'README'
create_file 'README', <<-TEXT
Welcome to #{@app_name}

================================

Admin Panel
* Visit /admin
* Please refer to db/seeds.rb for RailsAdmin default username and password
TEXT
remove_dir 'test'
run 'cp config/database.yml config/database.yml.example'
append_to_file '.gitignore', %Q{config/database.yml}

display "Git Initial Commit"
git :init
git :add => '.'
git :commit => "-aqm 'Initial commit'"
