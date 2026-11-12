class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "SCOTUSfiles <no-reply@scotusfiles.com>")
  layout "mailer"
end
