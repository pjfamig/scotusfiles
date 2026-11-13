require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    decisions(:paxton).imports.create!(refresh: true, succeeded: true, duration_ms: 1200, passages_count: 42)
    decisions(:pending).imports.create!(succeeded: false, error: "No opinion text found in PDF")
    TermSync.create!(term: 2025, listed_count: 12, queued_count: 1)
  end

  test "requires an admin" do
    get admin_root_path
    assert_redirected_to new_session_path

    sign_in_as users(:one)
    [ admin_root_path, admin_users_path, admin_comments_path, admin_imports_path ].each do |path|
      get path
      assert_response :forbidden
    end
  end

  test "overview shows signups, comments, decisions, and imports" do
    sign_in_as users(:admin)
    get admin_root_path

    assert_response :success
    assert_select "h1", "Overview"
    assert_select "li", text: /Ruth Reader/
    assert_select "p", text: "This is the crux of the case."
    assert_select "a", text: "Free Speech Coalition, Inc. v. Paxton"
    assert_select "span", text: "Refresh"
    assert_select "span", text: /12 opinions listed, 1 new or revised/
  end

  test "lists users with comment counts and search" do
    sign_in_as users(:admin)
    get admin_users_path(q: "ruth")

    assert_response :success
    assert_select "tbody tr", 1
    assert_select "tbody a[href=?]", admin_comments_path(user_id: users(:one).id), text: "1"
  end

  test "lists comments, filterable by user" do
    sign_in_as users(:admin)
    get admin_comments_path(user_id: users(:two).id)
    assert_response :success
    assert_select "li[id^=comment_]", 0

    get admin_comments_path
    assert_select "li[id^=comment_]", 1
  end

  test "filters imports" do
    sign_in_as users(:admin)
    get admin_imports_path(filter: "failed")

    assert_response :success
    assert_select "tbody tr", 1
    assert_select "tbody", text: /No opinion text found in PDF/
  end

  test "admins see the admin link in the header" do
    sign_in_as users(:admin)
    get root_path
    assert_select "header a[href=?]", admin_root_path

    sign_in_as users(:one)
    get root_path
    assert_select "header a[href=?]", admin_root_path, count: 0
  end
end
