require 'test_helper'

class DocsTest < ActionDispatch::IntegrationTest
  test "root renders the docs page" do
    get "/"

    assert_equal 200, status
    assert_select "h1", text: "Share benchmark results as a link"
    assert_select ".docs__faq-item h2", text: "Can I run my own instance?"
  end
end
