# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "dompurify", to: "https://cdn.jsdelivr.net/npm/dompurify@3.1.7/dist/purify.es.mjs"
pin "@yaireo/tagify/dist/tagify.esm.js",
    to: "https://cdn.jsdelivr.net/npm/@yaireo/tagify@4.35.4/dist/tagify.esm.min.js"