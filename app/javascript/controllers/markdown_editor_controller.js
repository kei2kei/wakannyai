import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static easyMDE;

  connect() {
    console.log('🚀 Stimulus Controller Connected');

    const textareaElement = this.element.querySelector('#markdown-editor');
    const previewContainer = this.element.querySelector('#preview-container');

    if (textareaElement && previewContainer && typeof EasyMDE !== 'undefined' && typeof marked !== 'undefined') {
      const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
      this.csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : null;

      if (!this.csrfToken) {
        console.error("❌ CSRFトークンが見つかりません。");
        return;
      }
      
      marked.setOptions({
        breaks: true,
        gfm: true,
        renderer: this.createMarkdownRenderer()
      });
      
      // クラスのプロパティとしてEasyMDEインスタンスを保持
      this.easyMDE = new EasyMDE({
        element: textareaElement,
        spellChecker: false,
        status: false,
        placeholder: "Markdownで記事を書いてください...",
        previewRender: (plainText) => marked.parse(plainText),
        toolbar: [
          "bold", "italic", "strikethrough", "heading", "|",
          "quote", "unordered-list", "ordered-list", "|",
          "link", 
          "|",
          "code", "table", "horizontal-rule", "|",
          {
            name: "upload-image",
            action: (editor) => this.triggerFileUpload(editor),
            className: "fa fa-upload",
            title: "画像をアップロード"
          },
          "|",
          "fullscreen"
        ],
        autosave: { enabled: false }
      });

      
      this.easyMDE.codemirror.on('change', () => this.updatePreview(this.easyMDE.value()));
      this.easyMDE.codemirror.getWrapperElement().addEventListener('drop', (e) => this.handleDrop(e));
      this.easyMDE.codemirror.getWrapperElement().addEventListener('paste', (e) => this.handlePaste(e));

      this.updatePreview(this.easyMDE.value());
    } else {
      console.error('❌ 必要な要素またはライブラリが読み込まれていません');
    }
  }

  updatePreview(markdownText) {
    const previewContainer = this.element.querySelector('#preview-container');
    if (!markdownText.trim()) {
      previewContainer.innerHTML = '<p class="text-gray-500">プレビューがここに表示されます</p>';
      return;
    }
    previewContainer.innerHTML = marked.parse(markdownText);
  }

  handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    const files = Array.from(e.dataTransfer.files);
    files.forEach(file => {
      if (file.type.startsWith('image/')) {
        this.handleImageUpload(file);
      }
    });
  }

  handlePaste(e) {
    const items = (e.clipboardData || e.originalEvent.clipboardData).items;
    if (items) {
      for (let i = 0; i < items.length; i++) {
        if (items[i].type.startsWith('image/')) {
          const file = items[i].getAsFile();
          if (file) {
            e.preventDefault(); // デフォルトの貼り付けを防ぐ
            this.handleImageUpload(file);
          }
          break;
        }
      }
    }
  }

  triggerFileUpload(editor) {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.multiple = true;
    input.onchange = (e) => {
      Array.from(e.target.files).forEach(file => this.handleImageUpload(file));
    };
    input.click();
  }

  handleImageUpload(file) {
    const uploadingText = `![アップロード中...](🔄 ${file.name})`;
    this.easyMDE.codemirror.replaceSelection(uploadingText);
    
    const formData = new FormData();
    formData.append('image', file);
    
    fetch("/api/upload-image", {
      method: 'POST',
      body: formData,
      headers: {
        "X-CSRF-Token": this.csrfToken
      }
    })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      return response.json();
    })
    .then(data => {
      const currentText = this.easyMDE.value();
      if (data.url) {
        const updatedText = currentText.replace(uploadingText, `![${file.name}](${data.url})`);
        this.easyMDE.value(updatedText);
      } else {
        this.handleUploadError(file.name, `サーバーレスポンスにurlキーがありません。`);
      }
    })
    .catch(error => {
      this.handleUploadError(file.name, error.message);
    });
  }

  handleUploadError(filename, errorMessage) {
    console.error('❌ アップロードエラー:', errorMessage);
    const currentText = this.easyMDE.value();
    const updatedText = currentText.replace(`![アップロード中...](🔄 ${filename})`, '');
    this.easyMDE.value(updatedText);
    alert(`画像のアップロードに失敗しました:\n${errorMessage}`);
  }

  // helper for marked.js
  createMarkdownRenderer() {
    const renderer = new marked.Renderer();
    renderer.image = function(href, title, text) {
      const titleAttr = title ? ` title="${title}"` : '';
      return `<img src="${href}" alt="${text}"${titleAttr} style="max-width: 100%; height: auto;" />`;
    };
    return renderer;
  }
}