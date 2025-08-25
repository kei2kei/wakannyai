// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM読み込み完了');
  
  const textareaElement = document.getElementById('markdown-editor');
  console.log('テキストエリア要素:', textareaElement);
  
  if (textareaElement) {
    // CDNが読み込まれるまで少し待つ
    setTimeout(() => {
      if (typeof EasyMDE !== 'undefined') {
        console.log('EasyMDE利用可能:', EasyMDE);
        
        const easyMDE = new EasyMDE({
          element: textareaElement,
          spellChecker: false,
          status: false,
          toolbar: [
            "bold", "italic", "heading", "|",
            "quote", "unordered-list", "ordered-list", "|",
            "link", "image", "|",
            "preview", "side-by-side", "fullscreen"
          ],
          placeholder: "Markdownで記述してください...",
          autosave: {
            enabled: false
          }
        });
        
        console.log('EasyMDE初期化成功！', easyMDE);
      } else {
        console.error('EasyMDEが読み込まれていません');
      }
    }, 100); // 100ms待機
  }
});