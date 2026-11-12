# A four-digit year in the Court's listing ("10/14/2026") used to be read as two digits
# ("20"), dating the decision to 2020. Those rows sit in a later term, so the year is recoverable.
class FixFourDigitYearDecisionDates < ActiveRecord::Migration[8.1]
  class Decision < ActiveRecord::Base; end

  def up
    Decision.where(decided_on: Date.new(2020, 1, 1)..Date.new(2020, 12, 31)).where("term > 2020").find_each do |decision|
      date = decision.decided_on
      decision.update_columns(decided_on: date.change(year: date.month >= 8 ? decision.term : decision.term + 1))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
