module CanonicalHostConstraint
  def self.matches?(request)
    canonical = Rails.configuration.x.canonical_host
    return false if canonical.blank? || request.host == canonical || request.path == "/up"

    request.host == canonical.delete_prefix("www.") || request.host.end_with?(".herokuapp.com")
  end
end
