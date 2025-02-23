" Requirements:
"   - you'll need VIM compiled with Ruby scripting support
"     - example: for Debian/Ubuntu: sudo apt-get install vim-ruby
"   - please, copy this file to one of your VIM dir
"     - example: to your .vim home folder: $HOME/.vim/vimlog.vim
"   - please, add this code to your .vimrc file:
"
"       if !exists('*Wordpress_vim')
"         runtime vimblog.vim
"       endif
"
"   - change your blog login/password info on the get_personal_data
"     function below. 
"   - make sure you have xmlrpc.php file in your / blog dir. If not, 
"     change the @xml variable to find it.
"   - testing: open vim, and do 
"       :Blog rp 
"     to get your recent 10 posts.

" Define the Blog command that checks for Ruby support when used
command! -nargs=* Blog if !has('ruby') | 
      \ echohl ErrorMsg | 
      \ echo "Error: This plugin requires Vim compiled with +ruby" |
      \ echohl None |
      \ else |
      \ call Wordpress_vim(<f-args>) |
      \ endif

" Vim syntax functions
function! Blog_syn_hl()    
  syntax clear
  syntax keyword wpType Post Title Date
  syntax region wpTitle start=/"/ end=/$/ 
  syntax region wpPostId start=/\[/ end=/\]/ 
  highlight wpType ctermfg=Green guifg=LightGreen
  highlight wpTitle cterm=bold ctermfg=Blue guifg=Blue guibg=LightCyan gui=bold
  highlight wpPostId ctermfg=Red guifg=Red
endfunction

function! Post_syn_hl()    
  syntax clear
  runtime! syntax/html.vim   
  syntax keyword wpType Post Title Date Author Link Permalink Allow Comments Allow Pings Categs  
  syntax region wpPostId start=/\[/ end=/\]/ contained
  syntax match wpFields /: .*/hs=s+2 contains=wpPostId 
  highlight wpType ctermfg=Green guifg=LightGreen gui=bold
  highlight wpPostId ctermfg=Red guifg=Red
  highlight wpFields ctermfg=Blue guifg=Blue guibg=LightCyan
endfunction

function! Wordpress_vim(start, ...)    
  call Blog_syn_hl()
  try
ruby <<EOF
  require 'xmlrpc/client'
  require 'time'
  
  class Wp_vim
    def initialize
      begin
        get_personal_data
        @blog = XMLRPC::Client.new(host: @site, path: @xml, port: @port)
        self.send("blog_#{VIM::evaluate('a:start')}")
      rescue XMLRPC::FaultException => e
        xmlrpc_flt_xcptn(e)
      end
    end
    
    def get_personal_data  
      @login = "USER_LOGIN" 
      @passwd = "USER_PASSWORD" 
      @site = "" 
      @xml = "/xmlrpc.php" 
      @port = 80 
      @blog_id = 0
      @user = 1
    end

    def get_post_content
      post_content = {}
      new_post = VIM::Buffer.current[1].upcase.start_with?("TITLE")
      post_content[:new_post] = new_post
      
      if new_post
        post_content[:title] = VIM::Buffer.current[1].gsub(/Title *:/, '').strip
        post_content[:dateCreated] = Time.parse(VIM::Buffer.current[2].gsub(/Date *:/, '').strip)
        post_content[:mt_allow_comments] = VIM::Buffer.current[3].gsub(/Comments *:/, '')
        post_content[:mt_allow_pings] = VIM::Buffer.current[4].gsub(/Pings *:/, '')
        post_content[:categories] = VIM::Buffer.current[5].gsub(/Categs *:/, '').split
        body = VIM::Buffer.current[8..].map(&:to_s)
        post_content[:description] = body.join("\r")
      else
        post_content[:post_id] = VIM::Buffer.current[1].gsub(/Post.*\[/, '').strip.chop
        post_content[:title] = VIM::Buffer.current[2].gsub(/Title *:/, '')
        post_content[:dateCreated] = Time.parse(VIM::Buffer.current[3].gsub(/Date *:/, '').strip)
        post_content[:mt_allow_comments] = VIM::Buffer.current[7].gsub(/Comments *:/, '')
        post_content[:mt_allow_pings] = VIM::Buffer.current[8].gsub(/Pings *:/, '')
        post_content[:categories] = VIM::Buffer.current[9].gsub(/Categs *:/, '').split
        body = VIM::Buffer.current[11..].map(&:to_s)
        post_content[:description] = body.join("\r")
      end
      
      post_content.merge!(
        mt_exceprt: '',
        mt_text_more: '',
        mt_tb_ping_urls: []
      )
    end  

    def blog_publish
      p = get_post_content
      resp = blog_api("publish", p, true, p[:new_post]) 
      if p[:new_post] && resp[:post_id]
        VIM::command("enew!")
        VIM::command("Blog gp #{resp[:post_id]}")
      end
    end

    def blog_draft
      p = get_post_content
      resp = blog_api("draft", p, false, p[:new_post]) 
      if p[:new_post] && resp[:post_id]
        VIM::command("enew!")
        VIM::command("Blog gp #{resp[:post_id]}")
      end
    end

    def blog_np
      @post_date = same_dt_fmt(Time.now)
      @post_author = @user
      VIM::command("call Post_syn_hl()")
      v = VIM::Buffer.current
      v.append(v.count-1, "Title    : ")
      v.append(v.count-1, "Date     : #{@post_date}")  
      v.append(v.count-1, "Comments : 1")
      v.append(v.count-1, "Pings    : 1")
      v.append(v.count-1, "Categs   : ")
      v.append(v.count-1, " ")
      v.append(v.count-1, " ")
      v.append(v.count-1, "<type from here...> ")
    end

    def blog_cl
      resp = blog_api("cl")
      VIM::command(":new")
      VIM::command("call Blog_syn_hl()")
      VIM::command(":set wrap")
      v = VIM::Buffer.current
      v.append(v.count, "CATEGORIES LIST: ")
      v.append(v.count, " ")
      v.append(v.count, "\"#{resp.join('  ')}\"")
    end

    def blog_rp
      num = if VIM::evaluate("a:0").to_i > 0
        n = VIM::evaluate("a:1")
        n.to_i.positive? ? n.to_i : 10
      else
        10
      end
      
      resp = blog_api("rp", num)
      VIM::command(":new")
      VIM::command("call Blog_syn_hl()")
      v = VIM::Buffer.current
      v.append(v.count, "MOST RECENT #{num} POSTS: ")
      v.append(v.count, " ")
      resp.each do |r|
        v.append(v.count, "Post : [#{r[:post_id]}]  Date: #{r[:post_date]}")
        v.append(v.count, "Title: \"#{r[:post_title]}\"")
        v.append(v.count, " ")
      end
    end

    def blog_gp
      VIM::command("call Post_syn_hl()")
      id = if VIM::evaluate("a:0").to_i > 0
        VIM::evaluate("a:1").presence
      end
      
      resp = blog_api("gp", id)
      v = VIM::Buffer.current
      v.append(v.count-1, "Post     : [#{resp[:post_id]}]")
      v.append(v.count-1, "Title    : #{resp[:post_title]}")
      v.append(v.count-1, "Date     : #{resp[:post_date]}")
      v.append(v.count-1, "Link     : #{resp[:post_link]}")
      v.append(v.count-1, "Permalink: #{resp[:post_permaLink]}")
      v.append(v.count-1, "Author   : #{resp[:post_author]}")
      v.append(v.count-1, "Comments : #{resp[:post_allow_comments]}")
      v.append(v.count-1, "Pings    : #{resp[:post_allow_pings]}")
      v.append(v.count-1, "Categs   : #{resp[:post_categories]}")
      v.append(v.count-1, " ")
      v.append(v.count-1, " ")
      resp[:post_body].each_line { |l| v.append(v.count-1, l.strip) }
    end

    def blog_del
      id = if VIM::evaluate("a:0").to_i > 0
        VIM::evaluate("a:1").presence
      end
      resp = blog_api("del", id)
      if resp
        VIM.command(%{echo "Blog post ##{id} successfully deleted"})
      else
        VIM.command(%{echo "Deletion problem for post id ##{id}"})
      end
    end

    def blog_link
      v = VIM::Buffer.current
      link = { link: '', string: '', title: '' }
      id = if VIM::evaluate("a:0").to_i > 0
        VIM::evaluate("a:1").presence
      end
      v.append(v.count-1, "  a:0 --> #{VIM::evaluate('a:0')}  ")
      v.append(v.count-1, "  a:1 --> #{VIM::evaluate('a:1')}  ")
      v.append(v.count-1, %{<a href="#{link[:link]}" title="#{link[:title]}">#{link[:string]}</a>})
    end

    def blog_api(fn_api, *args)
      case fn_api
      when "gp"
        resp = @blog.call("metaWeblog.getPost", args[0], @login, @passwd)
        @post_id = resp['postid']
        {
          post_id: resp['postid'],
          post_title: resp['title'],
          post_date: same_dt_fmt(resp['dateCreated'].to_time),
          post_link: resp['link'],
          post_permalink: resp['permalink'],
          post_author: resp['userid'],
          post_allow_comments: resp['mt_allow_comments'],
          post_comment_status: resp['comment_status'],
          post_allow_pings: resp['mt_allow_pings'],
          post_ping_status: resp['mt_ping_status'],
          post_categories: resp['categories'].join(' '),
          post_body: resp['description']
        }
      when "rp"
        resp = @blog.call("mt.getRecentPostTitles", @blog_id, @login, @passwd, args[0])
        resp.map do |r|
          {
            post_id: r['postid'],
            post_title: r['title'],
            post_date: r['dateCreated'].to_time
          }
        end
      when "cl"
        resp = @blog.call("mt.getCategoryList", @blog_id, @login, @passwd)
        resp.map { |r| r['categoryName'] }
      when "draft", "publish"
        call = args[2] ? "metaWeblog.newPost" : "metaWeblog.editPost"
        which_id = args[2] ? @blog_id : args[0][:post_id]
        resp = @blog.call(call, which_id, @login, @passwd, args[0], args[1])
        { post_id: resp }
      when "del"
        resp = @blog.call("metaWeblog.deletePost", "1234567890ABCDE", args[0], @login, @passwd)
        resp
      end
    rescue XMLRPC::FaultException => e
      xmlrpc_flt_xcptn(e)
    end

    def same_dt_fmt(dt)
      dt.strftime('%m/%d/%Y %H:%M:%S %Z')
    end

    def xmlrpc_flt_xcptn(excpt)
      msg = "Error code: #{excpt.faultCode} :: Error msg.:#{excpt.faultString}"
      VIM::command(%{echo "#{msg}"})
    end
  end

  Wp_vim.new
EOF
  catch /del/
    echo "Usage for deleting a post:"
    echo "  :Blog del id"
  catch /draft/
    echo "Usage for saving a draft of a post:"
    echo "  :Blog draft"
  catch /publish/
    echo "Usage for Publishing a post:"
    echo "  :Blog publish"
  catch /gc/
    echo "Usage for getting the list of Categories <new window>:"
    echo "  :Blog cl"
  catch /gp/
    echo "Usage for Get Post [id]:"
    echo "  :Blog gp id"
  catch /np/
    echo "Usage for New Post:"
    echo "  :Blog np"
  catch /rp/
    echo "Usage for Recent [x] Posts (defaults to last 10): <new window>"
    echo "  :Blog rp [x]"
  catch //
    echo "Usage is :Blog option [arg]"
    echo " switches:"
    echo "  - rp [x]   => show recent [x] posts"
    echo "  - gp id    => get post with identification id"
    echo "  - np       => create a new post"
    echo "  - publish  => publish an edited/new post" 
    echo "  - draft    => save edited/new post as draft"
    echo "  - gc       => get the list of categories"
    echo "  - del id   => delete post with identification id"
    echo "  --- syntax helpers:"
    echo "  - link ADDRESS,TITLE,STRING   => insert link <a href='ADDRESS' title='TITLE'>STRING</a> link"
  endtry
endfunction
