import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    console.log('🚀 Stimulus Controller Connected');

    const textareaElement = this.element.querySelector('#markdown-editor');
    const previewContainer = this.element.querySelector('#preview-container');

    if (textareaElement && previewContainer) {
      const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
      const csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : null;

      if (!csrfToken) {
        console.error("❌ CSRFトークンが見つかりません。");
        return;
      }

      marked.setOptions({
        breaks: true,
        gfm: true
      });

      const renderer = new marked.Renderer();
      renderer.image = function(href, title, text) {
        const titleAttr = title ? ` title="${title}"` : '';
        return `<img src="${href}" alt="${text}"${titleAttr} style="max-width: 100%; height: auto;" />`;
      };
      marked.setOptions({ renderer: renderer });
      this.updatePreview(textareaElement.value);

      const easyMDE = new EasyMDE({
        element: textareaElement,
        spellChecker: false,
        status: false,
        placeholder: "Markdownで記事を書いてください...",
        toolbar: [
          "bold", "italic", "strikethrough", "heading", "|",
          "quote", "unordered-list", "ordered-list", "|",
          "link",
          "|",
          "code", "table", "horizontal-rule", "|",
          {
            name: "upload-image",
            action: (editor) => {
              const input = document.createElement('input');
              input.type = 'file';
              input.accept = 'image/*';
              input.multiple = true;
              input.onchange = (e) => {
                Array.from(e.target.files).forEach(file => this.handleImageUpload(file, editor));
              };
              input.click();
            },
            className: "fa fa-upload",
            title: "画像をアップロード"
          },
          "|",
          "fullscreen"
        ],
        autosave: { enabled: false }
      });

      easyMDE.codemirror.on('change', () => this.updatePreview(easyMDE.value()));
      const editorWrapper = easyMDE.codemirror.getWrapperElement();
      editorWrapper.addEventListener('drop', (e) => this.handleDrop(e, easyMDE));
    } else {
      console.error('❌ 必要な要素またはライブラリが読み込まれていません');
    }
  }

  // Helper methods should be inside the class
  updatePreview(markdownText) {
    const previewContainer = this.element.querySelector('#preview-container');
    if (!markdownText.trim()) {
      previewContainer.innerHTML = '<p class="text-gray-500">プレビューがここに表示されます</p>';
      return;
    }
    previewContainer.innerHTML = marked.parse(markdownText);
  }

  handleImageUpload(file, editor) {
    const uploadingText = `![アップロード中...](🔄 ${file.name})`;
    editor.codemirror.replaceSelection(uploadingText);

    const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
    const csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : null;

    const formData = new FormData();
    formData.append('image', file);

    fetch("/api/upload-image", {
      method: 'POST',
      body: formData,
      headers: {
        "X-CSRF-Token": csrfToken
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then(data => {
      const currentText = editor.value();
      if (data.url) {
        const updatedText = currentText.replace(uploadingText, `![${file.name}](${data.url})`);
        editor.value(updatedText);
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
    const currentText = easyMDE.value();
    const updatedText = currentText.replace(`![アップロード中...](🔄 ${filename})`, '');
    easyMDE.value(updatedText);
    alert(`画像のアップロードに失敗しました:\n${errorMessage}`);
  }

  handleDrop(event, easyMDE) {
    event.preventDefault();
    event.stopPropagation();

    const files = Array.from(event.dataTransfer.files);
    files.forEach(file => {
      if (file.type.startsWith('image/')) {
        this.handleImageUpload(file, easyMDE);
      }
    });
  }
}