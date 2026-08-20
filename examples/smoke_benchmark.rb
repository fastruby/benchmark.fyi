# A small benchmark for checking that an instance of benchmark.fyi accepts and
# renders a report. Compares four ways of building the same string.
#
#   gem install benchmark-ips
#   SHARE_URL=http://localhost:3000 ruby examples/smoke_benchmark.rb
#
# Drop SHARE_URL and use SHARE=1 to share to https://ips.fastruby.io instead.

require 'benchmark/ips'

Benchmark.ips do |x|
  # The defaults are 2s warmup and 5s per report, which is slower than a smoke
  # test needs. Raise these when you care about the numbers.
  x.config(warmup: 1, time: 2)

  a, b, c = "a", "b", "c"

  x.report("interpolation") { "#{a}#{b}#{c}" }
  x.report("concat (+)")    { a + b + c }
  x.report("<< buffer")     { (+"") << a << b << c }
  x.report("format")        { format("%s%s%s", a, b, c) }

  # Adds the "times slower" column to the shared report. Without this the
  # report renders name and iterations/second only.
  x.compare!
end
