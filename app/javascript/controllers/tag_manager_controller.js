import { Controller } from "@hotwired/stimulus"
import Tagify from "@yaireo/tagify/dist/tagify.esm.js"

export default class extends Controller {
  connect() {
    const input = this.element.querySelector('input[name="post[tag_names]"]')
    if (!input) return

    this.tagify = new Tagify(input, {
      enforceWhitelist: false,
      dropdown: { enabled: 1, maxItems: 5, closeOnSelect: true, highlightFirst: true, fuzzySearch: false },
      originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(','),
    })

    this.onInput = this.onInput?.bind(this)
    this.tagify.on("input", this.onInput)
  }

  disconnect() {
    if (this.tagify) {
      this.tagify.off("input", this.onInput)
      this.tagify.destroy()
    }
  }

  async onInput(e) {
    const q = (e.detail?.value || "").trim()
    if (!q) { this.tagify.settings.whitelist = []; this.tagify.dropdown.hide(); return }

    try {
      const res = await fetch(`/tags/search?q=${encodeURIComponent(q)}`, { headers: { "Accept": "application/json" } })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const data = await res.json()

      // サーバが {value, id} を返す前提。もし {id, name} なら map で value に変換してOK
      const items = data.map(x => (x.value ? x : { value: x.name, id: x.id }))

      this.tagify.settings.whitelist = items
      this.tagify.dropdown.show(q)
    } catch (err) {
      console.error("Tagify fetch error:", err)
      this.tagify.settings.whitelist = []
      this.tagify.dropdown.hide()
    }
  }
}
