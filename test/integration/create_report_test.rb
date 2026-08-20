require 'test_helper'

class CreateReportTest < ActionDispatch::IntegrationTest
  RAW_JSON = "{\"entries\":[{\"name\":\"addition\",\"central_tendency\":27474451.540838767,\"ips\":27474451.540838767,\"error\":122038,\"stddev\":122038,\"microseconds\":1087174.973022461,\"iterations\":29868949,\"cycles\":2715359}],\"options\":{\"compare\":true}}"

  def created_report
    Report.find_from_short_id JSON.parse(response.body)["id"]
  end

  test "process json body with missing content_type" do
    # at the point of writing this, benchmark-ips makes this request with a raw string and no content type
    # this mimics that scenario
    post "/reports", params: RAW_JSON, headers: { "CONTENT_LENGTH" => RAW_JSON.length }

    assert_equal 200, status
  end

  test "accepts a json body sent with a form content type (benchmark-ips < 2.15.0)" do
    post "/reports",
         params: RAW_JSON,
         headers: {
           "CONTENT_TYPE" => "application/x-www-form-urlencoded",
           "CONTENT_LENGTH" => RAW_JSON.length
         }

    assert_equal 200, status
    assert_equal "addition", created_report.entries.first["name"]
    assert created_report.compare
  end

  test "accepts a json body sent with a json content type (benchmark-ips >= 2.15.0)" do
    post "/reports", params: JSON.parse(RAW_JSON), as: :json

    assert_equal 200, status
    assert_equal "addition", created_report.entries.first["name"]
    assert created_report.compare
  end
end
