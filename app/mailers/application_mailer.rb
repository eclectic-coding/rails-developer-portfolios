class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:smtp, :from)
  layout "mailer"
end
