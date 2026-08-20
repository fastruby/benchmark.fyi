require 'test_helper'

class ShareSnippetTest < ActionDispatch::IntegrationTest
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

  test "renders a markdown table alongside the html table" do
    report = Report.create!(
      report: [entry("fast", 500.0, 1.0), entry("slow", 100.0, 1.0)],
      compare: true,
      ruby: "4.0.6",
      os: "darwin",
      arch: "arm64"
    )

    get "/#{report.short_id}"

    assert_equal 200, status

    # the table is still there; the snippet is in addition to it, not instead
    assert_select "table.results"

    snippet = css_select(".share__snippet pre").first.text

    assert_includes snippet, "| name | iterations/second | slower |"
    assert_includes snippet, "| --- | --- | --- |"
    assert_includes snippet, "**fast**"
    assert_includes snippet, "| slow |"
    assert_includes snippet, "5.00x"
    assert_includes snippet, "ruby 4.0.6, darwin/arm64"
    assert_includes snippet, "/#{report.short_id}"
  end

  test "omits the slower column from the snippet for non comparison reports" do
    report = Report.create! report: [entry("only", 500.0, 1.0)]

    get "/#{report.short_id}"

    snippet = css_select(".share__snippet pre").first.text

    assert_includes snippet, "| name | iterations/second |"
    refute_includes snippet, "slower"
  end

  test "omits the environment line when the client sent no environment" do
    report = Report.create! report: [entry("only", 500.0, 1.0)]

    get "/#{report.short_id}"

    snippet = css_select(".share__snippet pre").first.text

    refute_includes snippet, "ruby "
    assert_includes snippet, "Full report:"
  end
end
