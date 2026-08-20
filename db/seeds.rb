# Sample reports, so the /:id page can be looked at without running a real
# benchmark first. Safe to run repeatedly: it does nothing when reports already
# exist unless you pass FORCE=1.
#
#   bin/rails db:seed

if Report.any? && !ENV["FORCE"]
  puts "Reports already exist (#{Report.count}). Pass FORCE=1 to add the samples anyway."
  exit
end

def entry(name, ips, stddev)
  {
    "name" => name,
    "central_tendency" => ips,
    "ips" => ips,
    "error" => stddev,
    "stddev" => stddev,
    "microseconds" => 2_000_000.0,
    "iterations" => (ips * 2).round,
    "cycles" => (ips / 10).round
  }
end

created = []

# A comparison report with one noisy entry, so the times-slower column and the
# high-deviation notice are both visible.
created << Report.create!(
  report: [
    entry("interpolation", 12_481_000.0, 149_772.0),
    entry("concat (+)", 9_204_000.0, 165_672.0),
    entry("<< buffer", 4_117_000.0, 345_828.0),
    entry("format", 1_902_000.0, 39_942.0)
  ],
  compare: true,
  ruby: "4.0.6",
  os: "darwin",
  arch: "arm64"
)

# No compare!, so the slower column is absent, and every entry is consistent, so
# there is no deviation notice.
created << Report.create!(
  report: [
    entry("Hash#fetch", 8_940_000.0, 62_580.0),
    entry("Hash#[]", 9_120_000.0, 72_960.0)
  ],
  ruby: "3.3.12",
  os: "linux",
  arch: "x86_64"
)

# An older client that sent no environment fields, so the meta row is empty.
created << Report.create!(
  report: [entry("nokogiri parse", 41_200.0, 1_648.0)],
  compare: true
)

puts "Created #{created.size} reports:"
created.each { |r| puts "  /#{r.short_id}" }
