

require 'reform/controls/combobox.rb'

module Reform

  class QColorListEditor < Qt::ComboBox
    private
      def initialize parent
        super
        populateList
        setProperty('color', Qt::Variant::from_value(Qt::Color.new(Qt::white)));
      end

      def populateList # FIXME: THIS IS BAD!!! INVESTIGATE: how to use AbstractListView with Qt::DecorationRole!!!
        # since basicly we use pairs here. -> connector: :name, deco_connector: :color   or something like this.
        colorNames = Qt::Color::colorNames
        colorNames.each_with_index do |name, i|
          color = Qt::Color.new(name)
          insertItem(i, name)
          setItemData(i, Qt::Variant.from_value(color), Qt::DecorationRole)
        end
      end

    public
      def color
        tag "color"
        itemData(currentIndex, Qt::DecorationRole).value
      end

      def color= color
        tag "color := #{color.inspect}"
        setCurrentIndex(findData(Qt::Variant.from_value(color), Qt::DecorationRole))
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), QColorListEditor, ComboBox

end