# lib/tasks/note.rake
require 'rss'
require 'open-uri'

namespace :note do
  desc "Noteに投稿した記事のインポート"
  task import_posts: :environment do
    NOTE_RSS_URL = 'https://note.com/kei2kei/rss'
    importer_user = User.first
    puts "インポート開始"

    begin
      rss_xml_data = URI.open(NOTE_RSS_URL).read
      nokogiri_doc = Nokogiri::XML(rss_xml_data)
      rss = RSS::Parser.parse(URI.open(NOTE_RSS_URL).read, false)
      namespaces = { 'media' => 'http://search.yahoo.com/mrss/' }
      rss.items.each do |item|
        note_thumbnail_url = nil
        item_node = nokogiri_doc.at_xpath("//item[link='#{item.link}']", namespaces)
        if item_node
          # 該当の <item> 要素の中から <media:thumbnail> 要素を探す
          thumbnail_node = item_node.at_xpath('media:thumbnail', namespaces)
          if thumbnail_node
            note_thumbnail_url = thumbnail_node.content.strip # ★要素のテキストコンテンツを取得★
          end
        end

        # Note記事のURLが既に存在するかチェックして重複を避ける
        unless Post.exists?(note_url: item.link)
          # PostモデルにNote記事として保存
          Post.create!(
            title: item.title, #Noteの記事のタイトル
            content: item.description, # contentをそのまま使うか、HTMLを加工するか検討
            note_url: item.link, # Noteの元のURL
            is_note_article: true,
            created_at: item.pubDate, # Noteの公開日時をそのまま使用
            updated_at: item.pubDate, # Noteの公開日時をそのまま使用
            user: importer_user,
            note_thumbnail_url: note_thumbnail_url
          )
          puts "インポートした記事: #{item.title}"
        else
          # 既に存在する場合はスキップ
          puts "スキップ: #{item.title} (既にインポート済み)"
        end
      end
      puts "インポート完了"
    rescue OpenURI::HTTPError => e
      puts "エラー: Note RSSフィードの取得に失敗しました。URLを確認してください。#{e.message}"
    rescue RSS::NotWellFormedError => e
      puts "エラー: 取得したRSSフィードの形式が不正です。#{e.message}"
    rescue => e
      puts "予期せぬエラーが発生しました: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
