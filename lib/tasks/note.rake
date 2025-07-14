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
      rss = RSS::Parser.parse(URI.open(NOTE_RSS_URL).read, false)
      rss.items.each do |item|
        # Note記事のURLが既に存在するかチェックして重複を避ける
        # 同じ記事を複数回インポートしないようにチェック
        unless Post.exists?(note_url: item.link)
          # PostモデルにNote記事として保存
          Post.create!(
            title: item.title, #Noteの記事のタイトル
            content: item.description, # contentをそのまま使うか、HTMLを加工するか検討
            note_url: item.link, # Noteの元のURL
            is_note_article: true,
            created_at: item.pubDate, # Noteの公開日時をそのまま使用
            updated_at: item.pubDate, # Noteの公開日時をそのまま使用
            user: importer_user
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
