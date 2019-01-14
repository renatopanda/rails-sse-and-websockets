require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get ticker" do
    get home_ticker_url
    assert_response :success
  end

end
