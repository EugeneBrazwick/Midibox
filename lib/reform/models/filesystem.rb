

# Note: I found there is also QFileSystemModel that serves a different
# purpose but probably could become a part of this one. Meaning:
# you could pass it as 'qtc'. That way a FileSystem could be immediately
# displayed in a QTreeView for example.
module Reform
  class FileSystem #            < AbstractModel         havoc with yaml
    include Model
    private
      def initialize parent, qtc = nil
#         tag "FileSystem.new"
        if Hash === parent
          setup(parent)
        else
          hash = Hash === qtc ? qtc : {}
#           if parent && parent.model?
#             @root = parent.root
#             @keypath = ?????
#           else
#             @root = self
#           end
          setup(hash)
        end
      end

      # dir. from where to start
      def dirname value = nil
        return @dirname unless value
        @dirname = value
        @file = nil
      end

      # class to instantiate by dynamic loaders (loader-specific)
      def klass value = nil
        return @klass unless value
        @klass = value
      end

      # basename of file
      def filename value = nil
        return @filename unless value
        @filename = value
        @file = nil
      end

      # file to load if 'filename' is nil.
      # However filename is not set.  This is used for 'fileNew'
      def default_filename value = nil
        return @default_filename unless value
        @default_filename = value
      end

      # If the opened file matches some pattern, the klass is used to load it by calling
      # klass::load.
      # The result must be a Model. If it is not Structure is wrapped around it.
      def register pattern, klass
        @reg[pattern] = klass
      end

      def model_postSetup
        @filename and load
      end

      def reset_captions
        @open_caption = @save_caption = @saveas_caption = nil
      end

      def load
#         tag "Load, filename = #@filename"
        unless @filename
          return unless @default_filename
          filename = @default_filename
#           dirty = true # new records are always dirty. Yes, but new records can always be easily
      # remade. Do not bug the user with 'save' boxes if he did not alter the empty record.
        else
          filename = @filename
        end
        for pattern, klass in @reg
          if filename =~ pattern
#             tag "Loading #@filename through #{klass}"
            model = klass::load(build_path(filename))
#             tag "loaded model #{model.inspect}"
            unless model.respond_to?(:model?) && model.model?
#               tag "Not a model!!! WRAPPING"
              model = (@klass || Structure).new(value: model, keypath: [])
            end
            @dirty = false
            return @file = model
          end
        end
      end

      def splitPath(filename)
        [File.dirname(filename), File.basename(filename)]
      end

      def store aPath
        dirname, filename = splitPath(aPath)
        for pattern, klass in @reg
          if filename =~ pattern
#             tag "Calling #{klass}::store #{@file.inspect}"
            raise Error, $qApp.tr("Refusing to save nil to #{aPath}, this must be some terrible mistake") unless @file
            klass::store(@file, aPath)
            @dirname, @filename = dirname, filename
            @dirty = false
            return
          end
        end
        raise Error, $qApp.tr("No storage class registered for '%s'") % filename
      end

      def build_path filename
        "#@dirname#{@dirname[-1] == '/' || filename && filename[0] == '/' ? '' : '/'}#{filename}"
      end

    public

      def setup hash, &block
        @dirname = Dir::getwd
        @filename = @default_filename = nil
        @itemname = $qApp.tr('an item')
        reset_captions
        @file = @klass = nil
        require 'reform/yamlloader'
        @reg = { /.yaml.gz$/ => CompressedYamlLoader,
                 /.yaml$/ => YamlLoader
               }
        if hash
          hash.each do |k, v|
            case k
            when :dirname then @dirname = v
            when :filename then @filename = v
            when :default_filename then @default_filename = v
            when :itemname then @itemname = v
            when :pattern, :filter then @pattern = v
            when :open_caption then @open_caption = v
            when :klass then @klass = v
            when :save_caption then @save_caption = v
            when :saveas_caption then @saveas_caption = v
            when :register then @reg.merge!(v)
            else
              raise ArgumentError, "Bad arg '#{k}'"
            end
          end
        elsif block
          instance_eval(&block)
        end
      end

      def path
        build_path(@filename)
      end

#       attr_accessor :dirname, :filename

      # for internal use only!!
      attr_writer :dirname, :filename

      # the default is 'an item', setting it resets all captions !!
      def itemname value = nil
        return @itemname unless value
        @itemname = value
        reset_captions
      end

      # set the pattern as expected by FileDialog. Use semicolon as separator.
      # Example:        pattern '*.png;*.jpg'
      def pattern value = nil
        return @pattern unless value
        @pattern = value
      end

      alias :filter :pattern            # this is how FileDialog calls it

      def new_caption value = nil
        if value
          @new_caption = value
        else
          @new_caption || $qApp.tr('Create a new %s') % @itemname
        end
      end

      # use this to set the whole caption for the file-open dialog
      # do not set itemname afterwards, that will erase it.
      def open_caption value = nil
        if value
          @open_caption = value
        else
          @open_caption || $qApp.tr('Pick %s') % @itemname.send($qApp.lang).a
        end
      end

      def save_caption value = nil
        if value
          @save_caption = value
        else
          @save_caption || $qApp.tr('Save %s') % @itemname.send($qApp.lang).a
        end
      end

      def saveas_caption value = nil
        if value
          @saveas_caption = value
        else
          @saveas_caption || @save_caption || $qApp.tr('Save %s as a different file') %
                                              @itemname.send($qApp.lang).a
        end
      end

      # set the path to load a file
      def path= filename
        return if !filename || filename.empty?
        pickup_tran do |tran|
#           tag "pickup_tran, sender = #{tran.sender}"
          org_dirname, org_filename = @dirname, @filename
          org_file = @file
          @dirname, @filename = splitPath(filename)
          unless tran.aborted?
            tran.addPropertyChange :dirname, org_dirname
            tran.addPropertyChange :filename, org_filename
            tran.addDependencyChange :path
            tran.addPropertyChange :file, org_file
#             tag "tran.changed_keys = #{tran.changed_keys.inspect}"
          end
          load # if this fails, then @dirname and @filename are left UNCHANGED automagically!!
#           tag "Did load, @file = #{@file.value.inspect}, propagate change"
        end
      end

      # reverse of save. Just open the file as set
      def open_file
        load
      end

        # shows FileDialog to open a file and assign the contents to _file_
      def open parent = nil
#         tag "open dirname=#@dirname, filename=#@filename"
        model_apply_setter(:path, Qt::FileDialog.getOpenFileName(parent && parent.qtc, open_caption,
                                                           @dirname, @pattern),
                     parent)
      end

      # returns the contents of the file. It should be a model
      def file
        @file || load
      end

      # this should save the model to disk again. Meant as 'save as'
      def saveas parent = nil
        pth = Qt::FileDialog.getSaveFileName(parent && parent.qtc, saveas_caption, path, @pattern) or return
        store(pth)
      end

      def save parent = nil
        return saveas unless @filename
        store(path)
      end

      def exists?
        File.exists?(path)
      end

      attr_writer :file

      # for use in prefab actions in the file menu!
      alias :fileNew :open_file         # no interaction
      alias :fileOpen :open
      alias :fileSave :save             # interaction if file was new
      alias :fileSaveAs :saveas

      def to_yaml_properties
        %w[ @dirname @filename @default_filename @itemname @pattern @open_caption
            @klass @save_caption @saveas_caption
          ]
      end

      attr_accessor :parent

      # true if the contents was changed, after loading or saving.
      def dirty?
        @dirty
      end
  end

  createInstantiator File.basename(__FILE__, '.rb'), nil, FileSystem

end
