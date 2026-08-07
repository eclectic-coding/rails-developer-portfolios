class AdminMailer < ApplicationMailer
  # Reports the outcome of DeveloperPortfoliosFetcher#fetch_and_sync (created,
  # updated, deactivated, and skipped-invalid counts, or the failure reason)
  # to the site admin after every run of FetchDeveloperPortfoliosJob.
  def feed_sync_report(result)
    recipient = Rails.application.credentials.admin_email
    if recipient.blank?
      Rails.logger.warn "AdminMailer#feed_sync_report: no admin_email configured in credentials, skipping delivery"
      return
    end

    @result = result
    status  = result.success? ? "succeeded" : "FAILED"

    mail(to: recipient, subject: "[Developer Portfolios] Feed sync #{status}")
  end
end
