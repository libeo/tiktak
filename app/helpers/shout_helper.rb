module ShoutHelper
  def format_message(m)
    m = Juggernaut.html_escape(m)
    m.gsub!(/\n/,'<br />')

    wrap_text(m, 300)

  end

end
