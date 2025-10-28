require 'test_helper'

class CreateReportTest < ActionDispatch::IntegrationTest
  test "process json body with missing content_type" do
    raw_json = "{\"entries\":[{\"name\":\"addition\",\"central_tendency\":27474451.540838767,\"ips\":27474451.540838767,\"error\":122038,\"stddev\":122038,\"microseconds\":1087174.973022461,\"iterations\":29868949,\"cycles\":2715359}],\"options\":{\"compare\":true}}"

    # at the point of writing this, benchmark-ips makes this request with a raw string and no content type
    # this mimics that scenario
    post "/reports", params: raw_json, headers: { "CONTENT_LENGTH" => raw_json.length }

    assert_equal 200, status
  end
end
