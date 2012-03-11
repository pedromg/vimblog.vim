# VIMBLOG.VIM

## Description

For Vi, Vim or GVim users, there is a simple way to manage your blog
posts.

In the Vim environment you can now

* create new blog posts
* edit / posts
* list all categories
* list older posts
* Promote turn "draft" posts into "published" (and vice-versa)

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
and then add this repository as a submodule with `git add
$GIT_REPO_PATH vimblog`.  Git will check out the plugin for you as a
[git submodule](http://book.git-scm.com/5_submodules.html)
1.  Your VIM runtime must be made aware of this plugin by means of the
    following command.  Make sure it is in your `~/.vimrc` or, for
MacVim + Janus users, make sure it is in `~/.vimrc.after`

          if !exists('\*Wordpress\_vim')
               runtime vimblog.vim
          endif

1.  Change your blog login/password info on the `get_personal_data`
    function in `vimblog.vim` near line 97.
1.  Set the `@site` value. Do not insert `http://`. Just insert the blog
    address, like in my case `blog.tquadrado.com`
1.  Make sure you have xmlrpc.php file in your / blog dir. If not,
    change the `@xml` variable in `vimblog.vim` to find it.
1.  To verify your installation, open vim, and do `:Blog rp` to get your
    recent 10 posts.

## Configuration

here are some globals you may define in your `.vimrc`.

`g:vimblogImageStyle="centered"` : This will provide CSS classes that
are applied to the `<img>` tags that result from using the media upload
function.  Typically you would add `centered` or `featured-image`.

## Known Issues

*Categories*:  Multiple categories on initial post creation is handled properly and multiple categories are comma-delimited.  Thus you can have a category like `Science and Technology` on a line with `Dinner` like
`Science and Technology, Dinner` and things are great.  When this is
retrieved *back*, the API does not preserve the separation either as
array elements or a delimited string and thus your separation breaks.
For the time being you must re-insert those commas.  Thankfully the
`:Blog cl` will help you build an accurate list.

## Troubleshooting

### "That Didn't work"
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
