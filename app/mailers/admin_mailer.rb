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

  # Notifies the site admin when a scheduled job (see config/recurring.yml) exhausts its
  # retries on an unhandled error, since Solid Queue otherwise just records a
  # SolidQueue::FailedExecution row with nobody watching for it.
  def job_failure_report(job_class_name, error, arguments)
    recipient = Rails.application.credentials.admin_email
    if recipient.blank?
      Rails.logger.warn "AdminMailer#job_failure_report: no admin_email configured in credentials, skipping delivery"
      return
    end

    @job_class_name = job_class_name
    @error           = error
    @arguments       = arguments

    mail(to: recipient, subject: "[Developer Portfolios] #{job_class_name} failed")
  end
end
