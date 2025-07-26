" Modernized WordPress Blogging Plugin for Vim (2025-ready)
" Maintainer: Cephus & ChatGPT refactor
" Requirements:
"   - Vim compiled with Ruby support (or standalone Ruby CLI fallback)
"   - Or run with Neovim (future CLI support planned)
" Usage:
"   - Put this file in ~/.vim/vimlog.vim
"   - Add to ~/.vimrc:
"       if !exists('*Wordpress_vim')
"         runtime vimblog.vim
"       endif
"   - Configure credentials in ~/.vim/blog_config.vim or via globals
"   - Commands: :BlogRecent, :BlogNew, :BlogPublish, etc.

scriptencoding utf-8

if !has('ruby')
    echohl WarningMsg | echom "Vim not compiled with +ruby. Using CLI fallback." | echohl None
    command! -nargs=* Blog call system('vimblog.rb ' . <q-args>)
    finish
endif

" --- CONFIG LOADING ---
if filereadable(expand("~/.vim/blog_config.vim"))
  source ~/.vim/blog_config.vim
endif

" Default globals (can be overridden in blog_config.vim)
if !exists('g:vimblog_login')
  let g:vimblog_login = "admin"
endif
if !exists('g:vimblog_passwd')
  let g:vimblog_passwd = "changeme"
endif
if !exists('g:vimblog_site')
  let g:vimblog_site = "example.com"
endif
if !exists('g:vimblog_xml')
  let g:vimblog_xml = "/xmlrpc.php"
endif
if !exists('g:vimblog_port')
  let g:vimblog_port = 80
endif

" --- SYNTAX HELPERS ---
function! Blog_syn_hl() abort
  silent! syntax clear
  syntax keyword wpType Post Title Date
  syntax region wpTitle start=/"/ end=/$/
  syntax region wpPostId start=/\[/ end=/\]/
  highlight wpType ctermfg=Green guifg=LightGreen
  highlight wpTitle cterm=bold ctermfg=Blue guifg=Blue guibg=LightCyan gui=bold
  highlight wpPostId ctermfg=Red guifg=Red
endfunction

function! Post_syn_hl() abort
  silent! syntax clear
  runtime! syntax/html.vim
  syntax keyword wpType Post Title Date Author Link Permalink Allow Comments Allow Pings Categs
  syntax region wpPostId start=/\[/ end=/\]/ contained
  syntax match wpFields /: .*/hs=s+2 contains=wpPostId
  highlight wpType ctermfg=Green guifg=LightGreen gui=bold
  highlight wpPostId ctermfg=Red guifg=Red
  highlight wpFields ctermfg=Blue guifg=Blue guibg=LightCyan
endfunction

" --- MAIN WRAPPER ---
command! -nargs=* Blog call Wordpress_vim(<f-args>)
command! -nargs=* BlogRecent call Wordpress_vim('rp', <f-args>)
command! -nargs=0 BlogNew call Wordpress_vim('np')
command! -nargs=0 BlogPublish call Wordpress_vim('publish')
command! -nargs=0 BlogDraft call Wordpress_vim('draft')
command! -nargs=* BlogGet call Wordpress_vim('gp', <f-args>)
command! -nargs=* BlogDelete call Wordpress_vim('del', <f-args>)
command! -nargs=0 BlogCategories call Wordpress_vim('cl')

function! Wordpress_vim(start, ...) abort
  call Blog_syn_hl()
  try
ruby <<EOF
require 'xmlrpc/client'
require 'time'

class WpVim
  def initialize
    @login = VIM::evaluate("g:vimblog_login")
    @passwd = VIM::evaluate("g:vimblog_passwd")
    @site = VIM::evaluate("g:vimblog_site")
    @xml = VIM::evaluate("g:vimblog_xml")
    @port = VIM::evaluate("g:vimblog_port").to_i
    @blog_id = 0
    @user = 1

    begin
      @blog = XMLRPC::Client.new(@site, @xml, @port)
      self.send("blog_" + VIM::evaluate("a:start"))
    rescue => e
      VIM::command("echohl ErrorMsg | echom 'Ruby Init Error: #{e.message}' | echohl None")
    end
  end

  # DRY for publishing/drafting
  def save_post(action, publish)
    p = get_post_content
    resp = blog_api(action, p, publish, p['new_post'])
    if p['new_post'] && resp['post_id']
      VIM::command("enew!")
      VIM::command("BlogGet #{resp['post_id']}")
    end
  end

  def blog_publish; save_post("publish", true); end
  def blog_draft; save_post("draft", false); end

  def blog_np
    @post_date = same_dt_fmt(Time.now)
    VIM::command("call Post_syn_hl()")
    v = VIM::Buffer.current
    [
      "Title    : ",
      "Date     : #{@post_date}",
      "Comments : 1",
      "Pings    : 1",
      "Categs   : ",
      " ", " ", "<type from here...> "
    ].each { |line| v.append(v.count-1, line) }
  end

  def blog_rp
    num = (VIM::evaluate("a:0").to_i > 0) ? VIM::evaluate("a:1").to_i : 10
    resp = blog_api("rp", num)
    VIM::command(":new")
    VIM::command("call Blog_syn_hl()")
    v = VIM::Buffer.current
    v.append(v.count, "MOST RECENT #{num} POSTS:")
    v.append(v.count, " ")
    resp.each do |r|
      v.append(v.count, "Post : [#{r['post_id']}]  Date: #{r['post_date']}")
      v.append(v.count, "Title: \"#{r['post_title']}\"")
      v.append(v.count, " ")
    end
  end

  def blog_gp
    VIM::command("call Post_syn_hl()")
    id = (VIM::evaluate("a:0").to_i > 0) ? VIM::evaluate("a:1") : nil
    resp = blog_api("gp", id)
    v = VIM::Buffer.current
    [
      "Post     : [#{resp['post_id']}]",
      "Title    : #{resp['post_title']}",
      "Date     : #{resp['post_date']}",
      "Link     : #{resp['post_link']}",
      "Permalink: #{resp['post_permalink']}",
      "Author   : #{resp['post_author']}",
      "Comments : #{resp['post_allow_comments']}",
      "Pings    : #{resp['post_allow_pings']}",
      "Categs   : #{resp['post_categories']}",
      " ", " "
    ].each { |line| v.append(v.count-1, line) }
    resp['post_body'].each_line { |l| v.append(v.count-1, l.strip) }
  end

  def blog_del
    id = (VIM::evaluate("a:0").to_i > 0) ? VIM::evaluate("a:1") : nil
    resp = blog_api("del", id)
    if resp
      VIM.command("echo 'Blog post ##{id} successfully deleted'")
    else
      VIM.command("echo 'Deletion problem for post id ##{id}'")
    end
  end

  def blog_cl
    resp = blog_api("cl")
    VIM::command(":new")
    VIM::command("call Blog_syn_hl()")
    v = VIM::Buffer.current
    v.append(v.count, "CATEGORIES LIST:")
    v.append(v.count, " ")
    v.append(v.count, "#{resp.join('  ')}")
  end

  # --- CORE XMLRPC API ---
  def blog_api(fn_api, *args)
    begin
      case fn_api
      when "gp"
        resp = @blog.call("metaWeblog.getPost", args[0], @login, @passwd)
        return {
          'post_id' => resp['postid'],
          'post_title' => resp['title'],
          'post_date' => same_dt_fmt(resp['dateCreated'].to_time),
          'post_link' => resp['link'],
          'post_permalink' => resp['permalink'],
          'post_author' => resp['userid'],
          'post_allow_comments' => resp['mt_allow_comments'],
          'post_allow_pings' => resp['mt_allow_pings'],
          'post_categories' => resp['categories'].join(' '),
          'post_body' => resp['description']
        }
      when "rp"
        resp = @blog.call("mt.getRecentPostTitles", @blog_id, @login, @passwd, args[0])
        resp.map { |r| {'post_id' => r['postid'], 'post_title' => r['title'], 'post_date' => r['dateCreated'].to_time} }
      when "cl"
        resp = @blog.call("mt.getCategoryList", @blog_id, @login, @passwd)
        resp.map { |r| r['categoryName'] }
      when "draft", "publish"
        call = args[2] ? "metaWeblog.newPost" : "metaWeblog.editPost"
        which_id = args[2] ? @blog_id : args[0]['post_id']
        resp = @blog.call(call, which_id, @login, @passwd, args[0], args[1])
        { 'post_id' => resp }
      when "del"
        @blog.call("metaWeblog.deletePost", "1234567890ABCDE", args[0], @login, @passwd)
      end
    rescue XMLRPC::FaultException => e
      xmlrpc_flt_xcptn(e)
      return {}
    rescue => e
      VIM::command("echohl ErrorMsg | echom 'API Error: #{e.message}' | echohl None")
      return {}
    end
  end

  def get_post_content
    post_content = {}
    new_post = VIM::Buffer.current[1][0..4].upcase == "TITLE"
    post_content['new_post'] = new_post
    if new_post
      post_content['title'] = VIM::Buffer.current[1].sub(/Title *:/, '').strip
      post_content['dateCreated'] = Time.parse(VIM::Buffer.current[2].sub(/Date *:/, '').strip)
      post_content['mt_allow_comments'] = VIM::Buffer.current[3].sub(/Comments *:/, '')
      post_content['mt_allow_pings'] = VIM::Buffer.current[4].sub(/Pings *:/, '')
      post_content['categories'] = VIM::Buffer.current[5].sub(/Categs *:/, '').split
      body = []
      8.upto(VIM::Buffer.current.count) { |line| body << VIM::Buffer.current[line] }
      post_content['description'] = body.join("\r")
    else
      post_content['post_id'] = VIM::Buffer.current[1].sub(/Post.*\[/, '').strip.chop
      post_content['title'] = VIM::Buffer.current[2].sub(/Title *:/, '')
      post_content['dateCreated'] = Time.parse(VIM::Buffer.current[3].sub(/Date *:/, '').strip)
      post_content['mt_allow_comments'] = VIM::Buffer.current[7].sub(/Comments *:/, '')
      post_content['mt_allow_pings'] = VIM::Buffer.current[8].sub(/Pings *:/, '')
      post_content['categories'] = VIM::Buffer.current[9].sub(/Categs *:/, '').split
      body = []
      11.upto(VIM::Buffer.current.count) { |line| body << VIM::Buffer.current[line] }
      post_content['description'] = body.join("\r")
    end
    post_content['mt_exceprt'] = ''
    post_content['mt_text_more'] = ''
    post_content['mt_tb_ping_urls'] = []
    post_content
  end

  def same_dt_fmt(dt)
    dt.strftime('%d/%m/%Y %H:%M:%S %Z')
  end

  def xmlrpc_flt_xcptn(excpt)
    msg = "Error code: #{excpt.faultCode} :: #{excpt.faultString}"
    VIM::command("echohl ErrorMsg | echom '#{msg}' | echohl None")
  end
end

WpVim.new
EOF
  catch /^Vim/
    echohl ErrorMsg | echom "Usage error or command failed." | echohl None
  endtry
endfunction

" --- BLOG CONFIG TEMPLATE (save as ~/.vim/blog_config.vim) ---
" let g:vimblog_login = "admin"
" let g:vimblog_passwd = "password"
" let g:vimblog_site = "yourblog.com"
" let g:vimblog_xml = "/xmlrpc.php"
" let g:vimblog_port = 80

" --- CLI FALLBACK SCRIPT TEMPLATE (save as ~/vimblog.rb) ---
" #!/usr/bin/env ruby
" require 'xmlrpc/client'
" puts "CLI fallback: process ARGV and talk to WordPress via XMLRPC"
