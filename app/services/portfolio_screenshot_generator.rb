class PortfolioScreenshotGenerator
  OUTPUT_DIR = Rails.root.join("tmp", "portfolio_screenshots").freeze

  def self.generate_for(portfolio)
    new(portfolio).generate
  end

  def initialize(portfolio)
    @portfolio = portfolio
  end

  def generate
    return nil unless @portfolio.active?
    return nil unless @portfolio.path.present?

    FileUtils.mkdir_p(OUTPUT_DIR)

    tmpfile = OUTPUT_DIR.join("portfolio_#{@portfolio.id}_#{Time.now.to_i}.png")

    # Call the Node/Playwright script via system. It should return exit status 0 on success.
    cmd = [
      "node",
      Rails.root.join("script", "capture_portfolio_screenshot.mjs").to_s,
      @portfolio.path,
      tmpfile.to_s
    ]

    success = system(*cmd)

    return nil unless success && File.exist?(tmpfile)

    File.open(tmpfile) do |file|
      @portfolio.site_screenshot.attach(
        io: file,
        filename: File.basename(tmpfile),
        content_type: "image/png"
      )
    end

    @portfolio
  rescue StandardError => e
    Rails.logger.error "Failed to generate screenshot for Portfolio##{@portfolio.id}: #{e.class} - #{e.message}"
    nil
  ensure
    # Cleanup temp file now that it has been attached (or if generation failed)
    FileUtils.rm_f(tmpfile) if defined?(tmpfile) && tmpfile && File.exist?(tmpfile)
  end
end
