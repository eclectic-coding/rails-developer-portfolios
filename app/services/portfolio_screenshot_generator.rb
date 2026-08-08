require "stringio"
require "securerandom"

class PortfolioScreenshotGenerator
  class CaptureError < StandardError; end

  OUTPUT_DIR = Rails.root.join("tmp", "portfolio_screenshots").freeze

  CONTENT_TYPE_EXTENSIONS = {
    "image/jpeg" => "jpg",
    "image/png" => "png",
    "image/webp" => "webp",
    "image/gif" => "gif",
    "image/svg+xml" => "svg"
  }.freeze

  def self.generate_for(portfolio)
    new(portfolio).generate
  end

  def initialize(portfolio)
    @portfolio = portfolio
  end

  # Prefers a site's og:image (fast, no browser needed); falls back to a
  # Playwright-rendered screenshot when no og:image is available or usable.
  # Raises CaptureError only when both strategies fail, so the job layer can
  # retry and eventually record the failure instead of it going unnoticed.
  def generate
    return nil unless @portfolio.active?
    return nil unless @portfolio.path.present?

    if attach_og_image
      mark_success(:og_image)
      return @portfolio
    end

    if attach_playwright_screenshot
      mark_success(:playwright)
      return @portfolio
    end

    raise CaptureError, @last_error.presence || "Unable to fetch og:image or capture a screenshot"
  end

  private

  def attach_og_image
    result = PortfolioOgImageFetcher.fetch(@portfolio.path)
    return false unless result

    extension = CONTENT_TYPE_EXTENSIONS.fetch(result.content_type, "img")
    @portfolio.site_screenshot.attach(
      io: StringIO.new(result.image_data),
      filename: "portfolio_#{@portfolio.id}_og.#{extension}",
      content_type: result.content_type
    )
    true
  rescue StandardError => e
    Rails.logger.warn "og:image attach failed for Portfolio##{@portfolio.id}: #{e.class} - #{e.message}"
    @last_error = e.message
    false
  end

  def attach_playwright_screenshot
    FileUtils.mkdir_p(OUTPUT_DIR)
    tmpfile = OUTPUT_DIR.join("portfolio_#{@portfolio.id}_#{Time.now.to_i}_#{SecureRandom.hex(4)}.png")

    # Call the Node/Playwright script via system. It should return exit status 0 on success.
    cmd = [
      "node",
      Rails.root.join("script", "capture_portfolio_screenshot.mjs").to_s,
      @portfolio.path,
      tmpfile.to_s
    ]

    success = system(*cmd)
    return false unless success && File.exist?(tmpfile)

    File.open(tmpfile) do |file|
      @portfolio.site_screenshot.attach(
        io: file,
        filename: File.basename(tmpfile),
        content_type: "image/png"
      )
    end

    true
  rescue StandardError => e
    Rails.logger.warn "Playwright capture failed for Portfolio##{@portfolio.id}: #{e.class} - #{e.message}"
    @last_error = e.message
    false
  ensure
    FileUtils.rm_f(tmpfile) if defined?(tmpfile) && tmpfile && File.exist?(tmpfile)
  end

  def mark_success(source)
    @portfolio.update!(
      screenshot_status: :success,
      screenshot_source: source.to_s,
      screenshot_error: nil,
      screenshot_attempted_at: Time.current
    )
  end
end
