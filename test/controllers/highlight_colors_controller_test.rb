require "test_helper"

class HighlightColorsControllerTest < ActionDispatch::IntegrationTest
  test "signed-in readers choose a highlight color" do
    sign_in_as users(:one)

    patch highlight_color_path, params: { highlight_color: "green" }, as: :turbo_stream

    assert_response :success
    assert_equal "green", users(:one).reload.highlight_color
    assert_match %(target="highlight_picker"), response.body
  end

  test "the chosen color is applied to the page" do
    users(:one).update!(highlight_color: "pink")
    sign_in_as users(:one)

    get root_path

    assert_select "html[data-highlight=pink]"
    assert_select "#highlight_picker button[aria-pressed=true][data-highlight=pink]"
  end

  test "unknown colors are rejected" do
    sign_in_as users(:one)

    patch highlight_color_path, params: { highlight_color: "chartreuse" }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_equal "yellow", users(:one).reload.highlight_color
  end

  test "guests get the default color and no picker" do
    get root_path

    assert_select "html[data-highlight=yellow]"
    assert_select "#highlight_picker", count: 0
  end

  test "guests must sign in to choose a color" do
    patch highlight_color_path, params: { highlight_color: "green" }

    assert_redirected_to new_session_path
  end
end
