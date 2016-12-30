require 'active_support/core_ext/string/strip'
require 'rexml/document'

module ESLintRails
  class CheckstyleFormatter

    def initialize(warnings, output_file = nil)
      @warnings = warnings
      @output_file = output_file

      @document = REXML::Document.new.tap do |d|
        d << REXML::XMLDecl.new
      end
      @checkstyle = REXML::Element.new('checkstyle', @document)
    end

    def format
      @warnings.group_by(&:filename).each do |filename, offenses|
        REXML::Element.new('file', @checkstyle).tap do |f|
          f.attributes['name'] = filename
          add_offences(f, offenses)
        end
      end

      output = ""
      @document.write output, 2

      puts "#{@warnings.size} warning(s) found."

      if @output_file.present?
        puts "Report saved to #{@output_file}."
        File.open(@output_file, "w") do |f|
          f.write output
        end
      else
        puts output
      end

    end

    private

    def add_offences parent, offenses
      offenses.each do |offense|
        REXML::Element.new('error', parent).tap do |e|
          e.attributes['line'] = offense.line
          e.attributes['column'] = offense.column
          e.attributes['severity'] = to_checkstyle_severity(offense.severity)
          e.attributes['message'] = offense.message
          e.attributes['source'] = "eslint.checkstyle.#{offense.node_type}/#{offense.rule_id}"
        end
      end
    end

    def max_length_of_attribute(attr_key)
      @warnings.map { |warning| warning.send(attr_key).size }.max
    end

    def to_checkstyle_severity(eslint_severity)
      case eslint_severity.to_s
      when 'fatal', 'error', 'high' then 'error'
      when 'warning' then 'warning'
      else 'info'
      end
    end
  end
end
