
require 'yaml'

module Reform

  # The nice thing is that Structure models can be loaded and saved to and from yaml
  # by adding precisely 39 chars of code:
  # def to_yaml(*a);@value.to_yaml(*a);end
  class YamlLoader
    public
      def self.load(path)
        YAML.load_file(path)
      end

      def self.store(model, path)
        File.open(path, 'w') { |f| YAML.dump(model, f) }
      end
  end

  class CompressedYamlLoader
    public
      def self.load(path)
        require 'shellwords'
        IO::popen('gunzip --to-stdout --decompress ' + Shellwords::shellescape(path), 'r') { |io| YAML.load(io) }
      end

      def self.store(model, path)
        require 'shellwords' # it is wrong to think we called load first!
        require 'tempfile'
        tmp = Tempfile.new('yamling', File.dirname(path))
        IO::popen('gzip > ' + Shellwords::shellescape(tmp.path), 'w') { |io| YAML.dump(model, io) }
#         tag "rename(#{tmp.path}, #{path})"
        File::rename(tmp.path, path)
      end
  end
end