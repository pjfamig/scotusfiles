require "application_system_test_case"

class OpinionsTest < ApplicationSystemTestCase
  setup do
    @opinion = opinions(:one)
  end

  test "visiting the index" do
    visit opinions_url
    assert_selector "h1", text: "Opinions"
  end

  test "should create opinion" do
    visit opinions_url
    click_on "New opinion"

    fill_in "Decision date", with: @opinion.decision_date
    fill_in "Full decision", with: @opinion.full_decision
    fill_in "Holding", with: @opinion.holding
    fill_in "Title", with: @opinion.title
    click_on "Create Opinion"

    assert_text "Opinion was successfully created"
    click_on "Back"
  end

  test "should update Opinion" do
    visit opinion_url(@opinion)
    click_on "Edit this opinion", match: :first

    fill_in "Decision date", with: @opinion.decision_date
    fill_in "Full decision", with: @opinion.full_decision
    fill_in "Holding", with: @opinion.holding
    fill_in "Title", with: @opinion.title
    click_on "Update Opinion"

    assert_text "Opinion was successfully updated"
    click_on "Back"
  end

  test "should destroy Opinion" do
    visit opinion_url(@opinion)
    click_on "Destroy this opinion", match: :first

    assert_text "Opinion was successfully destroyed"
  end
end
