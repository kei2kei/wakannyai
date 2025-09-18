import { Controller } from "@hotwired/stimulus";
import createDOMPurify from "dompurify";

export default class extends Controller {
  static targets = ["editor", "preview"]

  static values = {
    unattachedBlobs: Array,
    imagesAllowed: { type: Boolean, default: true },
    placeholder:   { type: String,  default: "Markdownで記事を書いてください..." }
  };

  initialize() {
    this._beforeCacheHandler = () => this.beforeCache();
  }

  connect() {
    console.log('🚀 Stimulus Controller Connected');
    document.addEventListener("turbo:before-cache", this._beforeCacheHandler);

    this.form = this.element.closest('form') || this.element.querySelector('form')
    const textareaElement = this.hasEditorTarget ? this.editorTarget : this.element.querySelector('textarea')
    this.previewContainer = this.hasPreviewTarget ? this.previewTarget : this.element.querySelector('[data-markdown-editor-target="preview"], #preview-container')
    this.DOMPurify = createDOMPurify(window);

    if (!this.form || !textareaElement || !this.previewContainer) {
      console.error("❌ フォーム、テキストエリア、またはプレビューコンテナが見つかりません。");
      return;
    }

    const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
    this.csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : null;

    this.uploadedBlobs = this.hasUnattachedBlobsValue ? [...this.unattachedBlobsValue] : [];

    if (!this.acquireExistingEditor(textareaElement)) {
      this.initEasyMDE(textareaElement);
    }

    this.updatePreview(textareaElement.value);
    this.applyHeights();
  }

  applyHeights() {
    if (this.easyMDE?.codemirror) {
      const wrapper = this.easyMDE.codemirror.getWrapperElement();
      wrapper.style.minHeight = `${this.editorHeightValue}px`;
      wrapper.closest('.EasyMDEContainer')?.classList.add('easy-mde-autogrow');
    }

    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add('easy-mde-preview-autogrow');
      this.previewTarget.style.removeProperty('height');
      this.previewTarget.style.removeProperty('maxHeight');
      this.previewTarget.style.overflowY = 'visible';
    }
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this._beforeCacheHandler);
    this.teardownEditor();
  }

  beforeCache() {
    this.teardownEditor();
  }

  initEasyMDE(textareaElement) {
    const escapeAttr = (s='') =>
      String(s).replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    const renderer = new marked.Renderer();
    // デフォルトでMarkdownの画像を認識しないためrendererを定義
    renderer.image = (href, title, text) => {
      const titleAttr = title ? ` title="${escapeAttr(title)}"` : '';
      return `<img src="${escapeAttr(href)}" alt="${escapeAttr(text)}"${titleAttr} style="max-width: 100%; height: auto;" />`;
    };

    marked.setOptions({
      breaks: true,
      gfm: true,
      renderer: renderer,
    });

    const baseToolbar = ["bold","italic","strikethrough","heading","|","quote",
                      "unordered-list","ordered-list","|","link","|","code",
                      "table","horizontal-rule","|","fullscreen"];

    const toolbar = [...baseToolbar];
    if (this.imagesAllowedValue) {
      toolbar.splice(12, 0, {
        name: "upload-image", action: () => this.triggerFileUpload(),
        className: "fa fa-upload", title: "画像をアップロード",
      });
    }

    this.easyMDE = new EasyMDE({
      element: textareaElement,
      spellChecker: false,
      status: false,
      placeholder: "Markdownで記事を書いてください...",
      previewRender: (plainText) => this.safeHTML(marked.parse(plainText)),
      toolbar,
      autosave: { enabled: false }
    });

    const wrapper = this.easyMDE.codemirror.getWrapperElement();
    if (this.imagesAllowedValue) {
      wrapper.addEventListener('drop',  (e) => this.handleDrop(e));
      wrapper.addEventListener('paste', (e) => this.handlePaste(e));
    }
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
    this.previewContainer.innerHTML = this.safeHTML(marked.parse(markdownText));
  }

  safeHTML(html) {
    return this.DOMPurify.sanitize(html, {
      ALLOWED_TAGS: [
        "p","br","strong","em","ul","ol","li","blockquote",
        "code","pre","h1","h2","h3","h4","h5","h6","a","img",
        "table","thead","tbody","tr","th","td","hr"
      ],
      ALLOWED_ATTR: [
        "href","target","rel",
        "src","alt","title","class","id",
        "width","height","srcset","sizes","loading","decoding"
      ],
      ALLOW_DATA_ATTR: false,
      FORBID_TAGS: ["style","script","iframe"],
      FORBID_ATTR: [/^on/i]
    });
  }

  triggerFileUpload() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.multiple = true;
    input.className = 'upload-input';
    input.style.position = 'fixed';
    input.style.left = '-9999px';
    document.body.appendChild(input);
    input.onchange = (e) => {
      Array.from(e.target.files).forEach(file => this.handleImageUpload(file));
      setTimeout(() => input.remove(), 0);
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

  insertTemplate() {
    const templateText = '## 問題\n\n\n\n## 試したこと\n\n\n\n## 期待する結果\n\n\n\n## 解決方法\n\n\n\n## まとめ';
    this.easyMDE.codemirror.replaceSelection(templateText);
  }

  acquireExistingEditor(textareaElement) {
    const wrapper = textareaElement.nextElementSibling;
    const cmEl = wrapper?.querySelector?.('.CodeMirror');
    const cm = cmEl && cmEl.CodeMirror;
    if (!cm) return false;

    this.cm = cm;
    this.easyMDE = {
      codemirror: cm,
      value: () => cm.getValue()
    };
    cm.on('change', () => {
      this.updatePreview(this.easyMDE.value());
      this.syncHiddenFields(this.easyMDE.value());
    });
    return true;
  }

  teardownEditor() {
    try {
      if (this.easyMDE?.toTextArea) {
        this.easyMDE.toTextArea();
      } else if (this.cm?.toTextArea) {
        this.cm.toTextArea();
      }
    } catch (e) {
      console.warn("Editor teardown failed:", e);
    } finally {
      this.easyMDE = null;
      this.cm = null;
    }
  }
}