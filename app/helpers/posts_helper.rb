module PostsHelper
  # 記事の内容(マークダウン)を保存前にHTMLにする
  def rendered_content_html(markdown_content)
    sanitized_html = sanitize Kramdown::Document.new(markdown_content).to_html
    raw(sanitized_html)
  end
end
