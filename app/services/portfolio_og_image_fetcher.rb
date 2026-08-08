require "net/http"
require "nokogiri"
require "resolv"
require "ipaddr"

# Looks up a site's og:image (falling back to twitter:image) meta tag and
# downloads it, so we can skip a full Playwright render when a curated
# preview image already exists. Returns nil for any expected "no image
# available" outcome (missing tag, unreachable site, non-image response) -
# absence isn't an error, it just means the caller should fall back to
# rendering a screenshot instead.
class PortfolioOgImageFetcher
  MAX_REDIRECTS = 3
  OPEN_TIMEOUT = 8
  READ_TIMEOUT = 8
  MAX_IMAGE_BYTES = 5.megabytes
  USER_AGENT = "Mozilla/5.0 (compatible; DeveloperPortfoliosBot/1.0)".freeze

  Result = Struct.new(:image_data, :content_type, keyword_init: true)

  def self.fetch(url)
    new(url).fetch
  end

  def initialize(url)
    @url = url
  end

  def fetch
    html = fetch_body(@url, limit: MAX_REDIRECTS)
    return nil if html.blank?

    image_url = extract_og_image_url(html, @url)
    return nil if image_url.blank?

    download_image(image_url, limit: MAX_REDIRECTS)
  rescue StandardError => e
    Rails.logger.debug "PortfolioOgImageFetcher: no usable og:image for #{@url} (#{e.class}: #{e.message})"
    nil
  end

  private

  def extract_og_image_url(html, base_url)
    doc = Nokogiri::HTML(html)
    node = doc.at_css('meta[property="og:image"]') ||
           doc.at_css('meta[name="og:image"]') ||
           doc.at_css('meta[name="twitter:image"]')

    content = node && node["content"]
    return nil if content.blank?

    URI.join(base_url, content).to_s
  rescue URI::InvalidURIError, ArgumentError
    nil
  end

  def fetch_body(url, limit:)
    return nil if limit <= 0

    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP)
    return nil unless public_host?(uri.host)

    response = http_get(uri)

    case response
    when Net::HTTPSuccess
      response.body
    when Net::HTTPRedirection
      location = response["location"]
      return nil if location.blank?

      fetch_body(URI.join(url, location).to_s, limit: limit - 1)
    end
  end

  def download_image(url, limit:)
    return nil if limit <= 0

    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP)
    return nil unless public_host?(uri.host)

    response = http_get(uri)

    case response
    when Net::HTTPSuccess
      content_type = response["content-type"].to_s
      return nil unless content_type.start_with?("image/")

      content_length = response["content-length"].to_i
      return nil if content_length.positive? && content_length > MAX_IMAGE_BYTES

      body = response.body
      return nil if body.blank? || body.bytesize > MAX_IMAGE_BYTES

      Result.new(image_data: body, content_type: content_type.split(";").first.strip)
    when Net::HTTPRedirection
      location = response["location"]
      return nil if location.blank?

      download_image(URI.join(url, location).to_s, limit: limit - 1)
    end
  end

  # Guards against SSRF: resolves the hostname and rejects it unless every
  # resolved address is public. Called on the original URL and on every
  # redirect hop (fetch_body/download_image re-check on each recursive
  # call), since a redirect can point anywhere regardless of where the
  # request started.
  def public_host?(host)
    addresses = Resolv.getaddresses(host)
    return false if addresses.empty?

    addresses.all? { |address| public_ip?(address) }
  rescue Resolv::ResolvError, Resolv::ResolvTimeout
    false
  end

  def public_ip?(address)
    ip = IPAddr.new(address)
    !(ip.loopback? || ip.private? || ip.link_local?)
  rescue IPAddr::Error
    false
  end

  def http_get(uri)
    Net::HTTP.start(
      uri.host, uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: OPEN_TIMEOUT,
      read_timeout: READ_TIMEOUT
    ) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      http.request(request)
    end
  end
end
