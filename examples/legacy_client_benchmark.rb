# Same as smoke_benchmark.rb, but forces the pre-2.15.0 client, which sends a
# JSON body with a form content type instead of application/json. Use this to
# exercise ReportsController#fix_missing_json_content_type.
#
#   gem install benchmark-ips -v 2.14.0
#   SHARE_URL=http://localhost:3000 ruby examples/legacy_client_benchmark.rb
#
# The `gem` call is required: `require` alone activates the newest installed
# version, so installing 2.14.0 next to a newer gem is not enough.

gem 'benchmark-ips', '2.14.0'
require 'benchmark/ips'

Benchmark.ips do |x|
  x.config(warmup: 1, time: 2)

  a, b, c = "a", "b", "c"

  x.report("interpolation") { "#{a}#{b}#{c}" }
  x.report("concat (+)")    { a + b + c }

  x.compare!
end
