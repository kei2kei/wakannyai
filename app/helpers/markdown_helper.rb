module MarkdownHelper
  SAFE_ATTRS = %w[href src alt class id target rel].freeze
  SAFE_TAGS  = %w[
    h1 h2 h3 h4 h5 h6 p br strong em ul ol li blockquote code pre
    a img table thead tbody tr td th
  ].freeze

  # 許可するURLスキーム
  SAFE_SCHEMES = %w[http https mailto].freeze

  def render_markdown(markdown)
    return ''.html_safe if markdown.blank?

    processed = markdown.gsub(/\t/, '    ')
    html = Kramdown::Document.new(processed, {
      input: 'GFM',
      syntax_highlighter: 'rouge',
      hard_wrap: false,
      auto_ids: true,
      toc_levels: (1..6),
      entity_output: :as_char
    }).to_html

    sanitized = sanitize(html, tags: SAFE_TAGS, attributes: SAFE_ATTRS)

    doc = Nokogiri::HTML::DocumentFragment.parse(sanitized)

    doc.css('a[href]').each do |a|
      href = a['href'].to_s.strip

      # javascript:, data: 等を除外（相対URLと # は許可）
      unless href.start_with?('/', '#') || SAFE_SCHEMES.any? { |s| href.downcase.start_with?("#{s}:") }
        a.remove_attribute('href')
      end

      a['target'] = '_blank'
      a['rel']    = 'noopener noreferrer nofollow'
    end

    doc.to_html.html_safe
  end
end
