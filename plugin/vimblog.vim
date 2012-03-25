" vim: set foldmethod=marker: "
" For use and setup documentation, consult the Readme.md file


" Vim syntax functions
" Language:     wordpress_vim
" Maintainer:   pedro mg <pedro.mota [at] gmail.com>
" Version:      1.1
" Last Change:  2012 Mar 08
" Remark:       Simple functions for vim blogging bundle in ruby.
" Remark:       Please, if you fine tune this code, send it back
" Remark:       for version upgrade ;)

" Highlighter functions{{{ 1
function! Blog_syn_hl()    " {{{2
  :syntax clear
  :syntax keyword wpType Post Title Date
  :syntax region wpTitle start=/"/ end=/$/
  :syntax region wpPostId start=/\[/ end=/\]/
  :highlight wpType ctermfg=Green guifg=LightGreen
  :highlight wpTitle cterm=bold ctermfg=Blue guifg=Blue guibg=LightCyan gui=bold
  :highlight wpPostId ctermfg=Red guifg=Red
endfunction
" }}}2

function! Post_syn_hl()    " {{{ 2
  :syntax clear
  :runtime! syntax/html.vim   " content syntax is html hl, except for headers
  :syntax keyword wpType Post Title Date Author Link Permalink Allow Comments Allow Pings Categs
  :syntax region wpPostId start=/\[/ end=/\]/ contained
  :syntax match wpFields /: .*/hs=s+2 contains=wpPostId
  :highlight wpType ctermfg=Green guifg=LightGreen gui=bold
  :highlight wpPostId ctermfg=Red guifg=Red
  :highlight wpFields ctermfg=Blue guifg=Blue guibg=LightCyan
endfunction
" }}} 2
" }}} 1

" Auxilary Ruby commands{{{ 2
function! CloseQuickfixAndOpenaPost(id) " {{{3
  cclose
  new
ruby <<EOF
  id = VIM::evaluate("a:id")
  Vim::command("Blog gp #{id}")
EOF
endfunction
" }}}3

function! WordpressViewWithChromeOnMac(...) " {{{ 3
  let l:storage = @@
  let @@ = 'none'

  execute "normal! gg/Link\<cr>f:2ly$g`."
  if @@ == 'none'
    echom("No preview URL found")
  else
    if (a:0 > 0 )
      let l:url = @@ . '&preview=true'
      let @@ = l:url
      echo('Previewing: ' . l:url)
    else
      let l:url = @@
      echo('Viewing: ' . l:url)
    endif
    exec(system("open -a \"Google Chrome\" \"". l:url  . "\""))
  endif

  let @@ = l:storage
endfunction
" }}}3

function! FetchPostIDBasedOnCurrentLine() " {{{ 3
  let l:temp = @@
  execute "normal! yy"
  let l:line = @@
  let @@ = l:temp
ruby <<EOF
  val = VIM::evaluate("l:line").gsub(/.*\[(\d+)\].*/, "\\1")
  VIM::command("let l:line = #{val}")
  VIM::command("Blog gp #{val}")
EOF
  return l:line
endfunction
" }}} 3
" }}} 2

" Vim blogging function
" Language:     vim script
" Interface:    ruby
" Maintainer:   pedro mg <pedro.mota [at] gmail.com>
" Version:      1.2
" Last Change:  2008 Jun 14
" Remark:       script function for vim blogging bundle in ruby.
" Remark:       Please, if you fine tune this code, send it back
" Remark:       for version upgrade ;)
" Remark:       V1.2 - commands added:
" Remark:              - Blog link ADDRESS,TITLE,STRING

:command! -nargs=* -complete=file Blog call Wordpress_vim(<f-args>)

function! Wordpress_vim(start, ...)    " {{{1
  if !has('ruby')
      echoerr("Vimblog is not operational since it was not compiled with a Ruby interpreter (+ruby)")
      finish
  endif
  if !exists("g:vimblogConfig")
      echoerr("Vimblog is not operational since its g:vimblogConfig does not exist.")
      finish
  endif

  call Blog_syn_hl() " comment out if you don't wish syntax highlight activation
  try
ruby <<EOF
  require 'xmlrpc/client.rb'
  require 'time.rb'
  class Wp_vim

    #######
    # class initialization. Instantiates the @blog class variable to
    # retain blog site information for future api calls
    #
    def initialize(selector, *args) #{{{2
      begin
        get_personal_data
        raise "Login credential was empty.  Vimblog needs configuration, probably." if @login.empty?

        args.flatten!

        @blog = XMLRPC::Client.new(@site, @xml, @port)
        disp_method = ('blog_' + selector).to_sym
        self.send(disp_method, args)
      rescue XMLRPC::FaultException => e
        xmlrpc_flt_xcptn(e)
      rescue => ex
        VIM::command("echo \"Unhandled Error:  #{ex} and #{ex.backtrace}\"")
      end
    end

    def method_missing(sym, *args)
      VIM.command("echo \"Vimblog fatal error: unable to resolve #{sym.to_s} with #{args}\"")
    end

    #######
    # class variables for personnal data. Please *change* them accordingly.
    # CHANGE HERE:
    def get_personal_data
      config = VIM::evaluate("g:vimblogConfig")
      VIM::command("echo \"Your g:vimblogConfig configuration was not set.  Check out the vimblog README.md\"") unless config
      @login   = config["login"]
      @passwd  = config["passwd"]
      @site    = config["site"]
      @xml     = config["xml_rpc_path"]
      @port    = config["port"]
      @blog_id = 0
      @user    = 1
    end


    def get_post_content #{{{2
      post_content = {}
      new_post = VIM::Buffer.current[1][0..4].upcase == "Title".upcase
      post_content['new_post'] = new_post
      case new_post
      when true
        post_content['title'] = (VIM::Buffer.current[1]).gsub(/Title *:/, '').strip
        post_content['dateCreated'] = Time.parse(((VIM::Buffer.current[2]).gsub(/Date *:/, '')).strip)
        post_content['mt_allow_comments'] = (VIM::Buffer.current[3]).gsub(/Comments *:/, '')
        post_content['mt_allow_pings'] = (VIM::Buffer.current[4]).gsub(/Pings *:/, '')
        post_content['categories'] = (VIM::Buffer.current[5]).split(':').last.sub(/^\s+/,'').split(',')
        body = [] # from line 7 to the end, grab the post body content
        7.upto(VIM::Buffer.current.count) { |line| body << VIM::Buffer.current[line] }
        post_content['description'] = body.join("\r")
      else
        post_content['post_id'] = ((VIM::Buffer.current[1]).gsub(/Post.*\[/, '')).strip.chop
        post_content['title'] = (VIM::Buffer.current[2]).gsub(/Title *:/, '')
        post_content['dateCreated'] = Time.parse(((VIM::Buffer.current[3]).gsub(/Date *:/, '')).strip)
        post_content['mt_allow_comments'] = (VIM::Buffer.current[7]).gsub(/Comments *:/, '')
        post_content['mt_allow_pings'] = (VIM::Buffer.current[8]).gsub(/Pings *:/, '')
        post_content['categories'] = (VIM::Buffer.current[9]).split(':').last.sub(/^\s+/,'').split(',')
        body = [] # from line 12 to the end, grab the post body content
        12.upto(VIM::Buffer.current.count) { |line| body << VIM::Buffer.current[line] }
        post_content['description'] = body.join("\r")
      end
      post_content['mt_exceprt'] = ''
      post_content['mt_text_more'] = ''
      post_content['mt_tb_ping_urls'] = []
      return post_content
    end

    #######
    # publish the post. Verifies if it is new post, or an editied existing one.
    #
    def blog_publish(*args) #{{{2
      p = get_post_content
      resp = blog_api("publish", p, true, p['new_post'])
      if (p['new_post'] and resp['post_id'])
      then
        VIM::command("enew!")
        VIM::command("Blog gp #{resp['post_id']}")
      end
    end

    #######
    # upload a media asset.  Returns the URL to the file
    #
    def blog_um(args)
      require 'xmlrpc/base64'
      require 'xmlrpc/client.rb'

      VIM::command("let l:storage = @@")

      data = {}

      full_path   = File.expand_path(args[0])
      raise "Could not gather a full file path" if full_path.empty?

      upload_name = full_path.split('/').last

      data['name'] = upload_name
      begin
        data['bits'] = XMLRPC::Base64.new(IO.read(full_path))
      rescue => ex
        VIM::command("echom \"Encoding failed because #{ex.to_s}\"")
      end

      result = blog_api("um", data)
      config = VIM::evaluate("g:vimblogConfig")
      gas    = config['image_style']
      VIM::command("echo \"Your g:vimblogConfig['image_style'] configuration was not set.  Check out the vimblog README.md\"") unless gas
      gas = (gas.nil? ? '' : 'class="' + gas + '"')
      url  = "<a target=\"_new\" href=\"#{result['url']}\"><img #{gas} src=\"#{result['url']}\" alt=\"#\"></a>"

      v = VIM::Buffer.current
      ln = v.line_number
      v.append(ln, url)
      VIM::command("normal! j==f#")
    end

    #######
    # save post as draft. Verifies if it is new post, or an editied existing one.
    #
    def blog_draft(*args) #{{{2
      p = get_post_content
      resp = blog_api("draft", p, false, p['new_post'])
      if (p['new_post'] and resp['post_id'])
      then
        VIM::command("enew!")
        VIM::command("Blog gp #{resp['post_id']}")
      end
      VIM::command("nnoremap <buffer> <Leader>p :call WordpressViewWithChromeOnMac('preview-mode')<cr>")
    end

    #######
    # new post. Creates a template for a new post.
    #
    def blog_np(*args) #{{{2
      @post_date = same_dt_fmt(Time.now)
      @post_author = @user
      VIM::command("call Post_syn_hl()")
      v = VIM::Buffer.current
      v.append(v.count-1, "Title    : ")
      v.append(v.count-1, "Date     : #{@post_date}")
      v.append(v.count-1, "Comments : 1")
      v.append(v.count-1, "Pings    : 1")
      v.append(v.count-1, "Categs   : ")
      v.append(v.count-1, "<Enter your content after this line - DO NOT DELETE THIS LINE>")
    end

    #######
    # list of categories. It is opened in a new quickfix window.
    # The window can be dismissed by 'q', but if you hit <CR> on a category's line,
    # that name will be yanked to the default buffer and quoted so that you can put it
    # in a post.
    #
    def blog_cl(*args) #{{{2
      VIM::command(%q`echo "before api call"`)
      resp = blog_api("cl")
      # create a new window with syntax highlight.
      # this allows you to rapidly close the window (q) and continue blogging.
      configure_quicklist do
        VIM::command(":set wrap")
        v = VIM::Buffer.current
        ["CATEGORIES LIST:", " ", resp].flatten.each do |str|
          v.append(v.count, str)
        end
        VIM::command(%q[nnoremap <buffer> <silent> <CR> :execute "normal! 0y$" \| :cclose<cr>])
      end
    end

    ####### # {{{3
    # Utility function used to create a quickfix window which can be closed
    # with a 'q' (similar to  what the Ack plugin does).  This can be overridden
    # by passing in a string ('action') which defines the RHS of a Vimscript
    # map statement e.g. configure_quicklist(%q{:echo 'moon base alpha!'})
    #
    # If a block is passed with additional VimRuby goodness, that will be executed
    # in the context of the new buffer.  It yields back the buffer.
    #
    def configure_quicklist(qaction=':cclose<cr>') #{{{2
      VIM::command(":copen 10")
      VIM::command("setlocal modifiable")
      VIM::command("call Blog_syn_hl()")
      VIM::command("nnoremap <silent> <buffer> q #{qaction}")
      v = VIM::Buffer.current
      yield v
    end

    #######
    # recent [num] posts. Gets some info for the most recent [num] or 10 posts
    #
    def blog_rp(*args) #{{{2
      VIM::evaluate("a:0").to_i > 0 ? ((num = VIM::evaluate("a:1")).to_i ? num.to_i : num = 10) : num = 10
      resp = blog_api("rp", num)
      # create a new window with syntax highlight.
      # this allows you to rapidly close the window (:q!) and get that post id.
      configure_quicklist do |buf|
        enter_action = ':call CloseQuickfixAndOpenaPost(FetchPostIDBasedOnCurrentLine())<cr>'
        VIM::command("nnoremap <silent> <buffer> <CR> #{enter_action}")

        buf.append(0, "Move your cursor to the line with the postID and hit <CR> to edit it.")
        buf.append(buf.count, " ")
        buf.append(buf.count, "#{num} MOST RECENT POSTS:")
        buf.append(buf.count, " ")

        resp.each { |r|
          buf.append(buf.count, "Post : [#{r['post_id']}]  Date: #{r['post_date']}")
          buf.append(buf.count, "Title: \"#{r['post_title']}\"")
          buf.append(buf.count, " ")
        }

      end
    end

    #######
    # get post [id]. Fetches blog post with id [id], or the last one.
    #
    def blog_gp(*args) #{{{2
      VIM::command("call Post_syn_hl()")
      VIM::evaluate("a:0").to_i > 0 ? ((id = VIM::evaluate("a:1")) ? id : id = nil) : id = nil
      resp = blog_api("gp", id)
      v = VIM::Buffer.current
      v.append(v.count-1, "Post     : [#{resp['post_id']}]")
      v.append(v.count-1, "Title    : #{resp['post_title']}")
      v.append(v.count-1, "Date     : #{resp['post_date']}")
      v.append(v.count-1, "Link     : #{resp['post_link']}")
      v.append(v.count-1, "Permalink: #{resp['post_permaLink']}")
      v.append(v.count-1, "Author   : #{resp['post_author']}")
      v.append(v.count-1, "Comments : #{resp['post_allow_comments']}")
      v.append(v.count-1, "Pings    : #{resp['post_allow_pings']}")
      v.append(v.count-1, "Categs   : #{resp['post_categories']}")
      v.append(v.count-1, " ")
      v.append(v.count-1, " ")
      resp['post_body'].each_line { |l| v.append(v.count-1, l.strip)}
      VIM::command("nnoremap <buffer> <Leader>p :call WordpressViewWithChromeOnMac()<cr>")
    end

    #######
    # delete post with id [id]. Asks for confirmation first
    #
    def blog_del(*args) #{{{2
      VIM::evaluate("a:0").to_i > 0 ? ((id = VIM::evaluate("a:1")) ? id : id = nil) : id = nil
      resp = blog_api("del", id)
      resp ? VIM.command("echo \"Blog post ##{id} successfully deleted\"") : VIM.command("echo \"Deletion problem for post id ##{id}\"")
    end

    #######
    # insert a link. Is it interesting to implement these options ?
    # ** http://address.com
    # ** title (hint)
    # ** string
    #
    def blog_link(*args) #{{{2
      v = VIM::Buffer.current
      link = {:link => '', :string => '', :title => ''}
      VIM::evaluate("a:0").to_i > 0 ? ((id = VIM::evaluate("a:1")) ? id : id = nil) : id = nil
      v.append(v.count-1, "  a:0 --> #{VIM::evaluate("a:0")}  ")
      v.append(v.count-1, "  a:1 --> #{VIM::evaluate("a:1")}  ")
      v.append(v.count-1, "<a href=\"#{link[:link]}\" title=\"#{link[:title]}\">#{link[:string]}</a>")
    end

    #######
    # api calls. Allways returns an hash so that if api is changed, only this
    # function needs to be changed. One can use between Blogger, metaWeblog or
    # MovableType very easily.
    #
    def blog_api(fn_api, *args) #{{{2
      begin
        case fn_api

        when "gp"
          resp = @blog.call("metaWeblog.getPost", args[0], @login, @passwd)
      @post_id = resp['postid']
          body = resp['description'] +
                 ( resp['mt_text_more'].empty? ?
                   '' : '<!--more-->' + resp['mt_text_more'] )
          return { 'post_id' => resp['postid'],
            'post_title' => resp['title'],
            'post_date' => same_dt_fmt(resp['dateCreated'].to_time),
            'post_link' => resp['link'],
            'post_permalink' => resp['permalink'],
            'post_author' => resp['userid'],
            'post_allow_comments' => resp['mt_allow_comments'],
            'post_comment_status' => resp['comment_status'],
            'post_allow_pings' => resp['mt_allow_pings'],
            'post_ping_status' => resp['mt_ping_status'],
            'post_categories' => resp['categories'].join(' '),
            'post_body' => body
          }

        when "rp"
                resp = @blog.call("mt.getRecentPostTitles", @blog_id, @login, @passwd, args[0])
          arr_hash = []
                resp.each { |r| arr_hash << { 'post_id' => r['postid'],
                                              'post_title' => r['title'],
                                              'post_date' => r['dateCreated'].to_time }
          }
          return arr_hash

        when "um"
          args =  ["metaWeblog.newMediaObject", @blog_id, @login, @passwd, args.pop]
          result = @blog.call *args
          return result

        when "cl"
                resp = @blog.call("mt.getCategoryList", @blog_id, @login, @passwd)
          arr_hash = []
                resp.each { |r| arr_hash << r['categoryName'] }
          return arr_hash

        when "draft"
          args[2] ? call = "metaWeblog.newPost" : call = "metaWeblog.editPost"
          args[2] ? which_id = @blog_id :  which_id = args[0]['post_id']
          resp = @blog.call(call, which_id, @login, @passwd, args[0], args[1])  # hash content, boolean state ("publish"|"draft")
          return { 'post_id' => resp }

        when "publish"
          call = args[2] ?  "metaWeblog.newPost" :  "metaWeblog.editPost"
          which_id = args[2] ?  @blog_id :   args[0]['post_id']
          resp = @blog.call(call, which_id, @login, @passwd, args[0], args[1])  # hash content, boolean state ("publish"|"draft")
          return { 'post_id' => resp }

         when "del"
          resp = @blog.call("metaWeblog.deletePost", "1234567890ABCDE", args[0], @login, @passwd)
          return resp

       end
      rescue XMLRPC::FaultException => e
        xmlrpc_flt_xcptn(e)
      end
    end

    #######
    # same datetime format for dates
    #
    def same_dt_fmt(dt) #{{{2
      dt.strftime('%m/%d/%Y %H:%M:%S %Z')
    end

    #######
    # exception handling error display message for communication problems
    #
    def xmlrpc_flt_xcptn(excpt) #{{{2
      msg = "Error code: #{excpt.faultCode} :: Error msg.:#{excpt.faultString}"
      VIM::command("echo \"#{msg}\"")
    end

  end # class Wp_vim
  Wp_vim.new(VIM::evaluate("a:start"), (VIM::evaluate("a:0") > 0 ?  VIM::evaluate("a:000") : '' ))
EOF
  catch /del/
    :echo "Usage for deleting a post:"
    :echo "  :Blog del id"
  catch /draft/
    :echo "Usage for saving a draft of a post:"
    :echo "  :Blog draft"
  catch /publish/
    :echo "Usage for Publishing a post:"
    :echo "  :Blog publish"
  catch /gc/
    :echo "Usage for getting the list of categories: <quickfix window>:"
    :echo "  :Blog cl"
  catch /gp/
    :echo "Usage for Get Post [id]:"
    :echo "  :Blog gp id"
  catch /np/
    :echo "Usage for New Post:"
    :echo "  :Blog np"
  catch /rp/
    :echo "Usage for Recent [x] Posts (defaults to last 10): <quickfix window>"
    :echo "  :Blog rp [x]"
  catch /um/
    :echo "Usage for Upload Media"
    :echo "  :Blog um [filename]"
  catch //
    :echo "Usage is :Blog option [arg]"
    :echo " switches:"
    :echo "  - rp [x]   => show recent [x] posts"
    :echo "  - gp id    => get post with identification id"
    :echo "  - np       => create a new post"
    :echo "  - um [f]   => upload media asset [path to asset]"
    :echo "  - publish  => publish an edited/new post"
    :echo "  - draft    => save edited/new post as draft"
    :echo "  - gc       => get the list of categories"
    :echo "  - del id   => delete post with identification id"
    :echo "  --- syntax helpers:"
    :echo "  - link ADDRESS,TITLE,STRING   => insert link <a href='ADDRESS' title='TITLE'>STRING</a> link"
  endtry
endfunction
" }}}1
