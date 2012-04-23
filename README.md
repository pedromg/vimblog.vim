# VIMBLOG.VIM

## Description

For Vi, Vim or GVim users, there is a simple way to manage your blog
posts.

In the Vim environment you can now:

* create new blog posts
* edit / posts
* list all categories
* list older posts
* Promote turn "draft" posts into "published" (and vice-versa)
* Upload media to your blog from within VIM and get a link to it
* *Mac+Wordpress+Chrome*:  After using `:Blog draft` you can preview
  your draft with `<Leader>p`, `\\p` by default.  Additionally, if you
  access a pre-existing post (`Blog rp`, then `<CR>` on a line with the ID
  in it), thereafter `\\p` will launch the entry in Chrome.

In short, if you've been hanging on to Textmate for its blogging bundle,
you now have a comparable featureset in Vim thanks to Vimblog and
[GIFL](http://github.com/sgharms/gifl).

It is an out-of-the-box solution that works for Wordpress, but which can
very easilly, be customized to manage Blogger, MovableType, TextPattern,
et al.  Its the beauty of Open Source software. Study the code, change
it, and use it. It is very safe to use it because unlike proprietary
software, you can check for "phone\_home" procedures, etc.

##  Requirements:

1.   You'll need VIM compiled with Ruby scripting support.  Check for
     this by executing `vim --version|grep ruby`. My result ([MacVim +
Janus](https://github.com/carlhuda/janus)) shows: `+reltime +rightleft +ruby +scrollbind +signs +smartindent -sniff +startuptime`.  This means that I have ruby scripting support compiled.  Debian/Ubuntu can install Ruby support with: `sudo apt-get install vim-ruby`
1.  To install you several options:
  1.  Copy this file to one of your VIM directories
    1.  *Pure Vim Example*: copy the script file to your .vim home folder: $HOME/.vim/vimlog.vim
    1.  *Pathogen Example*:  If you're using [Tim Pope's
        Pathogen](http://www.vim.org/scripts/script.php?script_id=2332),
go to your Pathogen root directory and then `git clone` this repository
    1.  *Janus Example*:  If you're using Janus then you're just a
        variation on the Pathogen setup.  Create a `~/.janus` directory
and then add this repository as a submodule with `git submodule add
$GIT_REPO_PATH vimblog`.  Git will check out the plugin for you as a
[git submodule](http://book.git-scm.com/5_submodules.html)
1.  Your VIM runtime must be made aware of this plugin by means of the
    following command.  Make sure it is in your `~/.vimrc` or, for
MacVim + Janus users, make sure it is in `~/.vimrc.after`

          if !exists('\*Wordpress\_vim')
               runtime vimblog.vim
          endif

1.  Update your configuration credentials as described in the next section    
1.  After completing configuration, you can verify your installation by opening vim, and executing `:Blog rp` to get your
    recent 10 posts.  If you see them, then congratulations, you're ready to go.

## Configuration

**YOU MUST** define the following global in your `.vimrc`.

          let g:vimblogConfig = {'login': '*username*', 'passwd': '*pw*', 'site': '*yoursite*', 'xml_rpc_path': '/xmlrpc.php', 'port': '80', 'image_style': '*classes you want to add to images*', additional_ft': *additional filetypes that a vimblog should syntax highlight with e.g. (markdown|textile|html) - if unset, vimblog buffers will only have 'vimblog' highlighting }

I put mine like so:

          let g:vimblogConfig = { ... my configuration dictionary ...}
          if !exists('\*Wordpress\_vim')
               runtime vimblog.vim
          endif

`image_style` : This will provide CSS classes that are applied to the
`<img>` tags that result from using the media upload function.
Typically you would add `centered` or `featured-image`.

Use of this configuration dictionary allows the configuration and the
code to be separated.

## Troubleshooting

### "That Didn't Work"
1.  Check if the script is being found, by typing :B + TAB key. Upon code completion, it is ok. Remember, capital B.
1.  If the error persist, check for the correct path for xmlrpc.php in @xml value.
1.  Open an issue on github

## LICENSE:

    Copyright (c) 2007 pedro mg

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to
    deal in the Software without restriction, including without limitation the
    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
    sell copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
