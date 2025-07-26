# Vim WordPress Blogging Plugin (2025 Edition)

## ✨ Overview
This plugin turns **Vim** into a WordPress editor with direct XML-RPC support via Ruby. You can:
- 📝 Create and edit blog posts
- 🚀 Publish or save drafts
- 📂 Browse recent posts and categories
- ❌ Delete posts
- 🖋 Insert links easily

Supports **Vim 9+** (2025-ready) and includes a **Ruby CLI fallback** for systems without Vim `+ruby` support.

---

## ⚙️ Requirements

- **Vim** compiled with `+ruby` (check with `vim --version | grep ruby`)
- Ruby (>= 3.0)
- WordPress site with **XML-RPC enabled** (`xmlrpc.php` must exist on your server)

Optional:
- Neovim (CLI fallback support planned)

---

## 📦 Installation

1️⃣ **Install Vim with Ruby support**
```bash
# Debian/Ubuntu
sudo apt-get install vim-nox

# macOS
brew install vim --with-ruby
```

2️⃣ **Place the plugin**
```bash
mkdir -p ~/.vim/plugin
cp vimblog.vim ~/.vim/plugin/
```

3️⃣ **Update `.vimrc`**
```vim
if !exists('*Wordpress_vim')
  runtime vimblog.vim
endif
```

4️⃣ **Create config file**
```vim
" ~/.vim/blog_config.vim
let g:vimblog_login = "your-username"
let g:vimblog_passwd = "your-password"
let g:vimblog_site = "example.com"
let g:vimblog_xml = "/xmlrpc.php"
let g:vimblog_port = 80
```

---

## 📜 Usage

### 🆕 Create a new post
```vim
:BlogNew
```
Opens a new buffer template with fields like `Title`, `Date`, etc.

### 🚀 Publish a post
```vim
:BlogPublish
```
Publishes the current buffer to WordPress.

### 💾 Save as draft
```vim
:BlogDraft
```
Saves your post as a draft.

### 📂 List recent posts
```vim
:BlogRecent [n]
```
Shows the **last n posts** (defaults to 10).

### 🔍 Get post by ID
```vim
:BlogGet <id>
```
Fetches and loads post into buffer for editing.

### ❌ Delete a post
```vim
:BlogDelete <id>
```
Deletes post after confirmation.

### 🏷 List categories
```vim
:BlogCategories
```
Opens a temporary window listing categories.

---

## 🛠 CLI Fallback

If Vim **does not** have Ruby support, the plugin will fall back to a Ruby CLI script:
```bash
~/.vim/vimblog.rb
```
This script must handle the same commands (e.g. `ruby vimblog.rb publish`).

---

## 🔐 Security Notes
- ✅ Supports password authentication.
- 🔜 Planned support for **application passwords** (WordPress 5.6+) and token-based auth.

---

## 📄 License
MIT License – free to modify and redistribute.

## 🤝 Contributing
Pull requests welcome! Submit improvements, fixes, or modern WordPress API integrations.

---

## 👤 Maintainers
- Original Author: Pedro Mota (2008)
- 2025 Refactor

Also, check this Vim colorscheme [vim_pr0kter](https://github.com/pedromg/vim_pr0kter).
Have fun 🎉
