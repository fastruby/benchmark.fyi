require 'test_helper'

class DocsTest < ActionDispatch::IntegrationTest
  test "root renders the docs page" do
    get "/"

    assert_equal 200, status
    assert_select "li b", text: "What is this?"
  end
end
