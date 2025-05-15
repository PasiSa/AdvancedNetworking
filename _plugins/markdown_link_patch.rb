module Jekyll
  module Converters
    class Markdown
      alias_method :old_convert, :convert

      def convert(content)
        content.gsub!(/\]\(([^)]+)\.md\)/, '](\1.html)')
        old_convert(content)
      end
    end
  end
end