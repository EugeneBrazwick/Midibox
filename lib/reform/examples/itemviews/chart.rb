
=begin

Let's think about external files and 'the model'.

Basicly the filesystem is a big tree.

The problem is, how do I instantiate an entry before I know the class?
How can I know the class?
If we say Dir['**/*.png'] results in a stringarray of matching files.
Normally one would use a FileOpenDialog to open a file. How does this
fit in?

For example our global model could have an entry filesystem, which
is a filesystem model. It contains the parameters to open files,
like patterns, extensions, rootdir etc.

It also has an extension -> class databasae (it can default to using mime info)
And you can register extra entries.
=end

require 'reform/app'
require 'reform/models/filesystem'

module Reform

  class ChartLoader
    public
      def self.load(path)
        result = []
        File.open(path) do |file|
          for line in file
            l = line.chomp # UGLY
            next if l.empty?
            section, count, color = l.split(',')
#             tag "section = #{section} color = #{color.inspect}, count = #{Integer(count)}"
            result << { section: section, count: Integer(count), color: color }
          end
        end
        result
      end

      def self.store(model, path)
#         tag "store(#{model}, #{path})"
        File.open(path, "w") do |file|
          model.each do |record|
#             tag "storing record #{record}, count = #{record.count}, [count] = #{record[:count]}"
            # SNAG ALERT: record is a Structure around Hash, so record.count
            # is the same as Hash.count, and not record[:count]
            # So it is the nr of assocs in it (always 3)!!
            # But that would be very bad. So the rule is: keys go first, then delegates.
            file.puts "#{record.section},#{record.count},#{record.color}"
          end
        end
      end
  end

end

Reform::app {

  struct current: nil, filesystem: nil
#   tag "CALLING #{@model}::root"
  raise "TOTAL CORRUPTION, model #{@model} has no root" unless @model.root
    # This is damn UGLY. The instantiator MUST be used (but how???)
  @model.filesystem = Reform::FileSystem.new(dirname: File.dirname(__FILE__) + '/images',
                                             filename: 'qtdata.cht',
                                             register: { /\.cht$/ => Reform::ChartLoader },
                                             itemname: 'a chart',
                                             pattern: '*.cht')
=begin DESIGN PROPOSAL

  struct {
    current nil
    filesystem {
      fieldname :filesystem
      dirname ..
      filename ...
      ....
    }
  }

so Model instantiators are executed and assigned through :fieldname
So it requires some 'Structure' logic in Model itself. Not unlike 'stretch' in Widget.

Slightly inconsistent. It should then also be:
    field {
      fieldname :current
      value nil
    }

iso just 'current' + value. We need another method_missing for this. But if we are in Structure,
then we could also say:

  struct {
    current = nil
    filesystem = filesystem {           # ruby will interpret this correctly!!
      ...
    }
  }

but the fieldname can no longer be 'filesystem'? Yes it can!
No it can't.  Since Structure.filesystem will then be ambiguous.
In fact we could better use a special class. For otherwise 'current = nil' will start a modeltransaction
+ propagation! A bit too soon it seems.
And the first syntax is still better (is it??)
The fact that each entry must be a name is something quite different than the other
constructors.

NEAT!! FIXME THEN!!
=end
  form {
    sizeHint 870, 550
    windowTitle tr('Chart')
=begin
    menuBar {
      menu {
        fs = $qApp.model.filesystem
        title tr('&File')
#         fileopen :filesystem             TODO make shortcut. Implicit: always on :root (?)#
        fileopen fs
        saveas fs
        quit
      }
    }
    statusBar
=end
    splitter              { #  CAN CAUSE RESIZE AVALANGE !!!!! qt BUG
#     frame {
#       hbox {
        table {
          # the table inside the list is precisely the contents of the loaded file
          model_connector [:root, :filesystem, :file]
          # local_connector or display_connector, decides what to display
          local_connector :section
          decorator :color
          # next is the key_connector:
          key_connector :section
          connector :current
        }
        pieview {
          sizeHint 800, 600
        }
#       pieview_rd # 100 % CPU LOAD TOO!!! if left unconnected!!
#       }
    }
  }
}
