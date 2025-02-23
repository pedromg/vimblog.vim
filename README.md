# vimblog.vim

### Description

[Vimblog.vim](https://www.vim.org/scripts/script.php?script_id=2030) is a `vim` script written in [Ruby](https://www.ruby-lang.org) that allows blog posts to be managed by commands inside the `vim` famous editor. Compatible with `Vi`, `Vim`, `GVim`, `MacVim` when compiled with `ruby` support.  
   
Under `Vim` environment, you can create new posts, list, edit, move to draft, publish, delete and fetch all the categories with the bellow usage.

### Usage

Usage is `:Blog option [arg]`. 

- `:Blog np` creates _new post_;
- `:Blog rp [n]` lists most _n_ _recent posts_ (defaults to 10);
- `:Blog gp [id]` _gets post_ with _id_, where you can edit it;
- `Blog del [id]` _deletes_ post with id;
- `Blog gc`: _gets categories_ list;
- `Blog draft` saves current post as _draft_;
- `Blog publish` _publishes_ the current post.
- `Blog link [ADDRESS],[TITLE],[STRING]` will insert a link <a href='ADDRESS' title='TITLE'>STRING</a>
   
   
It is out-of-the-box working for [Wordpress](https://wordpress.com), but should quite easilly be used for Blogger, MovableType, TextPattern or other platforms exposing API's.
   
Its the beauty of [open source software](https://en.wikipedia.org/wiki/Open_source). 
Study the code, change it and use it. 
   
It should be safe to use it because, unlike with [proprietary software](https://en.wikipedia.org/wiki/Proprietary_software), you can check for vulnerabilities like credentials theft, etc.

###  Requirements:

You'll need `vim` compiled with `ruby` scripting support.
You can check this by typing:

```shell
$ vim --version | grep ruby
```
on you current _shell_ session. The result will let you know if you have it or not. 

Example for a `vim` with non `ruby` support:
```shell
+cscope            +localmap          -ruby              +wildignore
```
Notice the _minus_ sign in `-ruby`. You'll want to see a _plus_ sign.

Example for a `ruby` supported vim:
```shell
-python3 +quickfix +reltime -rightleft +ruby +scrollbind +signs +smartindent
```



#### install on [Debian](https://packages.debian.org/search?mode=filename&suite=bullseye&section=all&arch=any&searchon=names&keywords=vim)/[Ubuntu](https://packages.ubuntu.com/vim):

```shell
$ sudo apt-get install vim-ruby
```
	 
#### install [MacVim](https://macvim-dev.github.io/macvim/) with [Homebrew](https://brew.sh):
You can try MacVim:

```shell
$ brew install macvim
```	 


### How-To	 

- copy `vimblog.vim` file to one of your `vim` scripts directory. Example to your `.vim` home folder:

`$HOME/.vim/vimlog.vim`

- add the following lines to your `.vimrc` file. If it does not exist, create it ($HOME/.vimrc):

```vim
if !exists('*Wordpress_vim')
   runtime vimblog.vim
endif
```
- open the vimblog.vim script and edit the personal data in the `get_personal_data` method approximatelly at line 97, update your blog login/password info; 
- `@site` value: do not insert “http://”. Just insert the blog address, something like _blog.exmaple.com_;
- `@xml` value: make sure you have `xmlrpc.php` file in your / blog dir. If not, change the `@xml` variable to the correct location;

##### Test the script:

- open `vim` and try to get your 10 most recent posts (rp):
```vim
:Blog rp
```

If you can see them, it’s fine. If not, test this:

- check if the script is being found, by typing :B + TAB key. If it auto-completes to _Blog_ it is finding the script. Remember, capital B.
- if error persist, check for the correct path for `xmlrpc.php` in `@xml` value.


Have fun 🎉

Also, check this Vim colorscheme [vim_pr0kter](https://github.com/pedromg/vim_pr0kter).



