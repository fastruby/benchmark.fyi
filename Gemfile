def next?
  File.basename(__FILE__) == "Gemfile.next"
end

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.12'

if next?
  gem 'rails', '~> 7.2.0'
else
  gem 'rails', '~> 7.1.0'
end
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'sass-rails'

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
end

group :test do
  gem 'minitest', '~> 5.25'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
