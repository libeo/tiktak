class WikiRevision < ActiveRecord::Base
  belongs_to :wiki_page
  belongs_to :user

#  CamelCase = /\b((?:[A-Z]\w+){2,})/
  WIKI_LINK = /\[\[\s*([^\]\s][^\]]+?)\s*\]\]/
#  LINK_TYPE_SEPARATION = Regexp.new('^(.+):((file)|(pic))$', 0, 'utf-8')

  TaskNumber = /#([0-9]+)/

  ALIAS_SEPARATION = Regexp.new('^(.+)\|(.+)$', 0, 'utf-8')

  after_save :update_references

  def update_references

    self.wiki_page.references.destroy_all if self.wiki_page.references.size > 0

    body.gsub!( WIKI_LINK ) { |m|
      match = m.match(WIKI_LINK)
      name = text = match[1]
      alias_match = match[1].match(ALIAS_SEPARATION)
      if alias_match
        name = alias_match[1]
        text = alias_match[2]
      end

      unless name.downcase.include? '://'
        ref = WikiReference.find(:first, :conditions => ["wiki_page_id = ? AND referenced_name = ?", self.wiki_page.id, name])
        unless ref
          ref = WikiReference.create(:wiki_page => self.wiki_page, :referenced_name => name )
          ref.save
        end
      end
    }

  end

  def to_html

#    body.gsub!( CamelCase ) { |m|
#      url = "/wiki/show/#{URI.encode(m)}"
#      url_class = 'internal'
#      url_class << '_missing' unless WikiPage.find(:first, :conditions => ['company_id = ? and name = ?', self.wiki_page.company_id, m])
#
#
#      "%(#{url_class})\"#{m}\":#{url}%"
#   }

    body.gsub!( WIKI_LINK ) { |m|
      match = m.match(WIKI_LINK)
      name = text = match[1]

      alias_match = match[1].match(ALIAS_SEPARATION)
      if alias_match
        name = alias_match[1]
        text = alias_match[2]
      end

      if name.downcase.include? '://'
        url = name
        url_class = 'external'
      else
        url = "/wiki/show/#{URI.encode(name)}"
        url_class = 'internal'
        url_class << '_missing' unless WikiPage.find(:first, :conditions => ['company_id = ? and name = ?', self.wiki_page.company_id, name])
      end

      "%(#{url_class})\"#{text}\":#{url}%"
    }


    body.gsub!( TaskNumber, '"#\1":/tasks/view/\1')

    RedCloth.new(body).to_html + "<br/>"

  end
end
