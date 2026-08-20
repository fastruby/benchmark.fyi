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
    assert_select "tr.is-fastest .results__label", text: "fast"
    assert_select "tr.is-fastest .results__tag", text: "fastest"
  end

  test "gives the page a heading and a scrollable results region" do
    report = Report.create! report: [entry("only", 500.0, 1.0)]

    get "/#{report.short_id}"

    assert_select "h1"
    assert_select ".results-wrap[tabindex=?][role=?]", "0", "region"
  end

  test "titles the page after the fastest entry" do
    many = Report.create! report: [entry("fast", 500.0, 1.0), entry("slow", 100.0, 1.0)]
    get "/#{many.short_id}"
    assert_select "title", text: "fast and 1 other - benchmark.fyi"

    one = Report.create! report: [entry("solo", 500.0, 1.0)]
    get "/#{one.short_id}"
    assert_select "title", text: "solo - benchmark.fyi"
  end

  test "warns when an entry has a high standard deviation" do
    report = Report.create! report: [entry("noisy", 100.0, 20.0)]

    get "/#{report.short_id}"

    assert_equal 200, status
    assert_select ".notice"
    # the noisy entry is marked in text, not by colour alone
    assert_select ".results__dev.is-noisy", text: /high/
  end

  test "omits the warning when every entry is consistent" do
    report = Report.create! report: [entry("steady", 1000.0, 1.0)]

    get "/#{report.short_id}"

    assert_equal 200, status
    assert_select ".notice", count: 0
  end

  test "renders the times slower column only for comparison reports" do
    plain = Report.create! report: [entry("a", 500.0, 1.0), entry("b", 100.0, 1.0)]

    get "/#{plain.short_id}"

    assert_select "th.results__slower", count: 0

    compared = Report.create!(
      report: [entry("a", 500.0, 1.0), entry("b", 100.0, 1.0)],
      compare: true
    )

    get "/#{compared.short_id}"

    assert_select "th.results__slower", text: "slower"
    assert_select "td.results__slower", text: "5.00x"
  end

  test "responds 404 for a report that does not exist" do
    missing = Report.new
    missing.id = 999_999

    get "/#{missing.short_id}"

    assert_equal 404, status
  end
end
