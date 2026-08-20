def next?
  File.basename(__FILE__) == "Gemfile.next"
end

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.6'

if next?
  gem 'rails', '~> 7.2.0'
else
  gem 'rails', '~> 7.1.0'
end
gem 'pg', '>= 0.18', '< 2.0'
# Pinned to the 2.x line so `bundle update` can take rack security patches
# without crossing into 3.x, which breaks report ingestion.
#
# benchmark-ips POSTs a JSON body and lets Net::HTTP default the content type
# to application/x-www-form-urlencoded, so Rails parses the JSON as form data.
# ReportsController#fix_missing_json_content_type repairs that by re-reading
# the raw body. Under rack 3 that read returns empty, because rack 3 no longer
# rewinds rack.input after form parsing, so the repair silently does nothing
# and the request 400s. Lift this pin once that method reads the body without
# depending on the rewind.
gem 'rack', '~> 2.2'
gem 'puma', '~> 8.0'
gem 'sass-rails'
gem 'ostruct'

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
end

group :test do
  gem 'minitest', '~> 5.25'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
