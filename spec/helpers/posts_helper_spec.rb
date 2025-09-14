# frozen_string_literal: true
require "rails_helper"

RSpec.describe PostsHelper, type: :helper do
  describe "#rendered_content_html" do
    it "危険なタグ/属性は落とし、img等の安全要素は残す" do
      md = <<~MD
        <script>alert(1)</script>
        <img src="/rails/active_storage/blobs/redirect/dummy" onerror="alert(1)" alt="ok">
        <a href="https://example.com" onclick="evil()">link</a>
      MD

      html = helper.rendered_content_html(md)

      expect(html).not_to include("<script")
      expect(html).not_to include("onerror=")
      expect(html).not_to include("onclick=")

      expect(html).to include("<img")
      expect(html).to include("href=\"https://example.com\"")
    end
  end
end
