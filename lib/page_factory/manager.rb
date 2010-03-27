class PageFactory
  class Manager
    class << self

      def prune!(klass=nil)
        by_factory = lambda do |descendant|
          klass.nil? ? true : descendant.name == klass.to_s.camelcase
        end
        PageFactory.descendants.select(&by_factory).each do |factory|
          parts = PagePart.find :all, :include => :page,
                  :conditions => ['pages.page_factory = :factory AND page_parts.name NOT IN (:parts)',
                                  {:factory => factory.name, :parts => factory.parts.map(&:name)}
                                 ]
          PagePart.destroy parts
        end
      end

      def update_parts
        PageFactory.descendants.each do |factory|
          Page.find(:all, :include => :parts, :conditions => {:page_factory => factory.name}).each do |page|
            existing = lambda { |f| page.parts.detect { |p| f.name == p.name } }
            page.parts.create factory.parts.reject(&existing).map(&:attributes)
          end
        end
      end

      def sync!
        PageFactory.descendants.each do |factory|
          Page.find(:all, :include => :parts, :conditions => {:page_factory => factory.name}).each do |page|
            unsynced = lambda { |p| factory.parts.detect { |f| f.name == p.name and f.class != p.class } }
            unsynced_parts = page.parts.select(&unsynced)
            page.parts.destroy unsynced_parts
            needs_update = lambda { |f| unsynced_parts.map(&:name).include? f.name }
            page.parts.create factory.parts.select(&needs_update).map &:attributes
          end
        end
      end

    end
  end
end