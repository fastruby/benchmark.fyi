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

    # Built from the entries themselves rather than a hardcoded string: Ruby
    # 3.4 changed Hash#inspect to put spaces around `=>`, and the message
    # interpolates the entry directly.
    first, second = report.entries
    expected = "missing attributes: #{first} (ips, stddev), #{second} (stddev)"

    assert_equal [expected], report.errors[:entries]
  end

  test "short_id encodes the id with the base58 alphabet" do
    report = Report.new
    report.id = 58

    assert_equal "21", report.short_id
  end

  test "short_id round trips through find_from_short_id" do
    report = Report.create! report: [{
      name: "test",
      ips: 10.1,
      stddev: 0.3,
      microseconds: 3322,
      iterations: 221,
      cycles: 16
    }]

    assert_equal report, Report.find_from_short_id(report.short_id)
  end

  test "find_from_short_id rejects characters outside the base58 alphabet" do
    error = assert_raises(ArgumentError) do
      Report.find_from_short_id("0")
    end

    assert_equal "Value passed not a valid Base58 String.", error.message
  end
end
