module MarkdownHelper
  include ActionView::Helpers::SanitizeHelper

  def render_markdown(markdown)
    return "".html_safe if markdown.blank?

    processed = markdown.gsub(/\t/, "    ")

    html = Kramdown::Document.new(
      processed,
      input: "GFM",
      syntax_highlighter: "rouge",
      hard_wrap: false,
      auto_ids: true,
      toc_levels: (1..6),
      entity_output: :as_char
    ).to_html

    # 先に許可タグ・属性でサニタイズ（あとで rel/target を追加するので許可に含める）
    sanitized = sanitize(
      html,
      tags: %w[h1 h2 h3 h4 h5 h6 p br strong em ul ol li blockquote code pre a img table thead tbody tr td th],
      attributes: %w[href src alt class id rel target]
    )

    # リンクに rel/target を強制付与
    doc = Nokogiri::HTML::DocumentFragment.parse(sanitized)
    doc.css('a[href]').each do |a|
      a["target"] = "_blank"
      a["rel"]    = "noopener noreferrer nofollow"
    end

    doc.to_html.html_safe
  end
end
