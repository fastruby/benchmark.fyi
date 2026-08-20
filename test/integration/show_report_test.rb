require 'test_helper'

class ShowReportTest < ActionDispatch::IntegrationTest
  def entry(name, ips, stddev)
    {
      name: name,
      ips: ips,
      stddev: stddev,
      microseconds: 3322,
      iterations: 221,
      cycles: 16
    }
  end

  test "marks the fastest entry in bold" do
    report = Report.create! report: [entry("slow", 100.0, 1.0), entry("fast", 500.0, 1.0)]

    get "/#{report.short_id}"

    assert_equal 200, status
    assert_select "td b", text: "fast"
  end

  test "warns when an entry has a high standard deviation" do
    report = Report.create! report: [entry("noisy", 100.0, 20.0)]

    get "/#{report.short_id}"

    assert_equal 200, status
    assert_select "div.panel"
  end

  test "omits the warning when every entry is consistent" do
    report = Report.create! report: [entry("steady", 1000.0, 1.0)]

    get "/#{report.short_id}"

    assert_equal 200, status
    assert_select "div.panel", count: 0
  end

  test "renders the times slower column only for comparison reports" do
    plain = Report.create! report: [entry("a", 500.0, 1.0), entry("b", 100.0, 1.0)]

    get "/#{plain.short_id}"

    assert_select "th", text: "times slower", count: 0

    compared = Report.create!(
      report: [entry("a", 500.0, 1.0), entry("b", 100.0, 1.0)],
      compare: true
    )

    get "/#{compared.short_id}"

    assert_select "th", text: "times slower"
    assert_select "td", text: "5.00x"
  end

  test "responds 404 for a report that does not exist" do
    missing = Report.new
    missing.id = 999_999

    get "/#{missing.short_id}"

    assert_equal 404, status
  end
end
