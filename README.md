# Rails Admin App Template

A [Rails Template](http://m.onkey.org/rails-templates) to setup Rails applications with [RailsAdmin](https://github.com/sferik/rails_admin).

## Features

* Setup project rvm (Inspired from [greendog99/greendog-rails-template](https://github.com/greendog99/greendog-rails-template)
* Install [RSpec](https://github.com/dchelimsky/rspec), [Cucumber](https://github.com/cucumber/cucumber), [FactoryGirl](https://github.com/thoughtbot/factory_girl)
* Install [RailsAdmin](https://github.com/sferik/rails_admin)
* Generate Administrator model
* Setup Admin::Sessions controller which uses [RailsAdmin](https://github.com/sferik/rails_admin) theme for user to login Admin Panel (under /admin/administrators/sign_in)
* Setup git
* Modify README

## Prerequisites

* Ruby 1.8.7 or 1.9.2+
* Rails 3.1+
* [RVM](https://rvm.beginrescueend.com/)

## Usage

`rails new appname -d mysql -m https://raw.github.com/pinglamb/rails_admin_template/master/template.rb --skip-bundle`

## TODO

See [Github Issues](https://github.com/pinglamb/rails_admin_template/issues)

## References and Useful Links

* [RailsAdmin](https://github.com/sferik/rails_admin)
* [greendog99/greendog-rails-template](https://github.com/greendog99/greendog-rails-template)
* [RailsCasts #148 App Templates in Rails 2.3](http://railscasts.com/episodes/148-app-templates-in-rails-2-3)
* [Thor](https://github.com/wycats/thor)
