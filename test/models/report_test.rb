require 'test_helper'


class ReportTest < ActiveSupport::TestCase
  test "validates required attributes" do
    report = Report.new({
      entries: [{
        name: "test",
        ips: 10.1,
        central_tendency: 10.1,
        error: 23666,
        stddev: 0.3,
        microseconds: 3322,
        iterations: 221,
        cycles: 16
      }]
    })

    assert report.valid?
  end

  test "requires entries" do
    report = Report.new()

    assert report.invalid?

    assert_equal report.errors[:entries], ["can't be blank"]
  end

  test "shows invalid entries if validation fails" do
    report = Report.new({
      entries: [{
        name: "test",
        central_tendency: 10.1,
        error: 23666,
        microseconds: 3322,
        iterations: 221,
        cycles: 16
      },
      {
        name: "test2",
        central_tendency: 10.1,
        microseconds: 3322,
        iterations: 221,
        ips: 4,
        cycles: 16
      }]
    })

    assert report.invalid?

    assert_equal report.errors[:entries], ['missing attributes: {"name"=>"test", "central_tendency"=>10.1, "error"=>23666, "microseconds"=>3322, "iterations"=>221, "cycles"=>16} (ips, stddev), {"name"=>"test2", "central_tendency"=>10.1, "microseconds"=>3322, "iterations"=>221, "ips"=>4, "cycles"=>16} (stddev)']
  end
end
