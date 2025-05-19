module Jekyll
  module MdLinkFilter
    def convert_md_links(input)
      input.gsub(/href="([^"]+)\.md"/i, 'href="\1"')
    end
  end
end

Liquid::Template.register_filter(Jekyll::MdLinkFilter)
