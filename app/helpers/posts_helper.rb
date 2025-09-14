module PostsHelper
  # 記事の内容(マークダウン)を保存前にHTMLにする
  def rendered_content_html(markdown_content)
    return '' if markdown_content.blank?

    # タブをスペース4つに変換
    processed_content = markdown_content.gsub(/\t/, '    ')

    # kramdownでHTML変換
    html = Kramdown::Document.new(processed_content, {
      input: 'GFM',                    # GitHub Flavored Markdown
      syntax_highlighter: 'rouge',    # シンタックスハイライト
      hard_wrap: false,                # 改行の扱い
      auto_ids: true,                  # 見出しに自動でIDを付与
      toc_levels: (1..6),             # 目次レベル
      entity_output: :as_char          # HTML実体参照の出力方法
    }).to_html

    # サニタイズして安全にする
    sanitized_html = sanitize(html, tags: %w[
      h1 h2 h3 h4 h5 h6 p br strong em ul ol li blockquote code pre
      a img table thead tbody tr td th
    ], attributes: %w[href src alt class id])

    doc = Nokogiri::HTML::DocumentFragment.parse(sanitized_html)
    doc.css('a[href]').each do |a|
      a['target'] = '_blank'
      a['rel'] = 'noopener noreferrer nofollow'
    end
    raw(doc.to_html)
  end
end
