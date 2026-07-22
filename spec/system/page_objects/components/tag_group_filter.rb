# frozen_string_literal: true

module PageObjects
  module Components
    class TagGroupFilter < PageObjects::Components::Base
      CATEGORY_OUTLET = ".category-navigation-outlet"

      def has_dropdown_group_header?(name)
        has_css?("#{CATEGORY_OUTLET} .custom-dropdown-group h4", text: name)
      end

      def has_box_group_header?(name)
        has_css?("#{CATEGORY_OUTLET} .custom-box-group h4", text: name)
      end

      def has_no_filter_groups?
        has_no_css?("#{CATEGORY_OUTLET} .custom-dropdown-group") &&
          has_no_css?("#{CATEGORY_OUTLET} .custom-box-group")
      end

      def has_active_box_tag?(name)
        has_css?("#{CATEGORY_OUTLET} .custom-box-group li.active a", text: name)
      end

      def click_box_tag(name)
        find("#{CATEGORY_OUTLET} .custom-box-group li a", text: name).click
      end

      def tag_dropdown
        PageObjects::Components::SelectKit.new("#{CATEGORY_OUTLET} .tag-drop")
      end
    end
  end
end
