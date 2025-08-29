import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // サーバーから渡された未添付のBlob情報を受け取るためのValue
  static values = {
    unattachedBlobs: Array
  };

  connect() {
    console.log('🚀 Stimulus Controller Connected');

    this.form = this.element.querySelector('form');
    const textareaElement = this.element.querySelector('#markdown-editor');
    this.previewContainer = this.element.querySelector('#preview-container');

    if (!this.form || !textareaElement || !this.previewContainer) {
      console.error("❌ フォーム、テキストエリア、またはプレビューコンテナが見つかりません。");
      return;
    }

    const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
    this.csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : null;

    // バリデーションエラーによる再描画時に、サーバーから渡された情報で状態を復元します
    this.uploadedBlobs = this.hasUnattachedBlobsValue ? [...this.unattachedBlobsValue] : [];

    this.initEasyMDE(textareaElement);

    this.updatePreview(textareaElement.value);
  }

  initEasyMDE(textareaElement) {
    const renderer = new marked.Renderer();
    // デフォルトでMarkdownの画像を認識しないためrendererを定義
    renderer.image = (href, title, text) => {
      const titleAttr = title ? ` title="${title}"` : '';
      return `<img src="${href}" alt="${text}"${titleAttr} style="max-width: 100%; height: auto;" />`;
    };
    marked.setOptions({
      breaks: true,
      gfm: true,
      renderer: renderer,
    });

    this.easyMDE = new EasyMDE({
      element: textareaElement,
      spellChecker: false,
      status: false,
      placeholder: "Markdownで記事を書いてください...",
      previewRender: (plainText) => marked.parse(plainText),
      toolbar: [
        "bold", "italic", "strikethrough", "heading", "|", "quote", "unordered-list", "ordered-list", "|",
        "link", "|", "code", "table", "horizontal-rule", "|",
        {
          name: "upload-image",
          action: () => this.triggerFileUpload(),
          className: "fa fa-upload",
          title: "画像をアップロード",
        },
        "|", "fullscreen",
      ],
      autosave: { enabled: false }
    });

    const wrapper = this.easyMDE.codemirror.getWrapperElement();
    wrapper.addEventListener('drop', (e) => this.handleDrop(e));
    wrapper.addEventListener('paste', (e) => this.handlePaste(e));
    // プレビューの同期&隠しフィールドの同期
    this.easyMDE.codemirror.on('change', () => {
      const markdownText = this.easyMDE.value();
      this.updatePreview(markdownText);
      this.syncHiddenFields(markdownText);
    });
  }

  updatePreview(markdownText) {
    if (!markdownText.trim()) {
      this.previewContainer.innerHTML = '<p class="text-gray-500 italic">ここに内容のプレビューが表示されます</p>';
      return;
    }
    this.previewContainer.innerHTML = marked.parse(markdownText);
  }

  triggerFileUpload() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.multiple = true;
    input.onchange = (e) => {
      Array.from(e.target.files).forEach(file => this.handleImageUpload(file));
    };
    input.click();
  }

  handleDrop(e) {
    e.preventDefault();
    e.stopPropagation();
    const files = Array.from(e.dataTransfer?.files || []);
    files.forEach(file => {
      if (file.type.startsWith('image/')) this.handleImageUpload(file);
    });
  }

  handlePaste(e) {
    const items = (e.clipboardData || e.originalEvent.clipboardData)?.items;
    if (!items) return;
    for (const item of items) {
      if (item.type.startsWith('image/')) {
        const file = item.getAsFile();
        if (file) {
          e.preventDefault();
          this.handleImageUpload(file);
        }
        break;
      }
    }
  }

  handleImageUpload(file) {
    const uploadingText = `![アップロード中...](Uploading ${file.name}...)`;
    this.easyMDE.codemirror.replaceSelection(uploadingText);

    const formData = new FormData();
    formData.append('image', file);

    fetch("/api/upload-image", {
      method: 'POST',
      body: formData,
      headers: { "X-CSRF-Token": this.csrfToken }
    })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      return response.json();
    })
    .then(data => {
      if (data.url && data.signed_id && data.blob_id) {
        const markdownImage = `![${file.name}](${data.url})`;
        const currentText = this.easyMDE.value().replace(uploadingText, markdownImage);
        this.easyMDE.value(currentText);

        this.uploadedBlobs.push({
          id: data.blob_id,
          url: data.url,
          signed_id: data.signed_id
        });
        this.syncHiddenFields(this.easyMDE.value());
      } else {
        throw new Error("サーバーからのレスポンスが不正です。");
      }
    })
    .catch(error => this.handleUploadError(uploadingText, error.message));
  }

  handleUploadError(uploadingText, errorMessage) {
    console.error('❌ アップロードエラー:', errorMessage);
    const currentText = this.easyMDE.value().replace(uploadingText, '');
    this.easyMDE.value(currentText);
    alert(`画像のアップロードに失敗しました:\n${errorMessage}`);
  }

  syncHiddenFields(currentText) {
    // エディタ本文内の画像と隠しフィールドの画像を比較
    this.uploadedBlobs.forEach(blob => {
      const isPresentInText = currentText.includes(blob.url);
      const imageField = this.findHiddenField("post[images][]", blob.signed_id);
      const purgedField = this.findHiddenField("post[purged_image_ids][]", blob.signed_id);

      if (isPresentInText) {
        // 本文にある場合は隠しアップロード用フィールドに追加
        if (!imageField) this.addHiddenField("post[images][]", blob.signed_id);
        if (purgedField) purgedField.remove();
      } else {
        // 本文内に無い場合は削除用隠しフィールドに追加
        if (imageField) imageField.remove();
        if (!purgedField) this.addHiddenField("post[purged_image_ids][]", blob.signed_id);
      }
    });
  }

  addHiddenField(name, value) {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    this.form.appendChild(input);
  }

  findHiddenField(name, value) {
    return this.form.querySelector(`input[type="hidden"][name="${name}"][value="${value}"]`);
  }
}