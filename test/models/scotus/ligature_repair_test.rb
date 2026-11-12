require "test_helper"

class Scotus::LigatureRepairTest < ActiveSupport::TestCase
  test "restores words that lost their fi and fl ligatures" do
    text = "The frst offcer fled a petition to refect the specifc confict."

    assert Scotus::LigatureRepair.broken?([ text ])
    assert_equal "The first officer filed a petition to reflect the specific conflict.", Scotus::LigatureRepair.repair(text, broken: true)
  end

  test "leaves text alone when ligatures were extracted correctly" do
    text = "The suspect fled before the first officer arrived."

    assert_not Scotus::LigatureRepair.broken?([ text ])
    assert_equal text, Scotus::LigatureRepair.repair(text, broken: false)
  end

  test "preserves capitalization" do
    assert_equal "First FIFTH", Scotus::LigatureRepair.repair("Frst FFTH", broken: true)
  end
end
