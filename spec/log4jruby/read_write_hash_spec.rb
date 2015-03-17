require 'spec_helper'

require 'log4jruby'

module Log4jruby
  describe ReadWriteHash do

    subject { Logger.get('Test', :level => :debug) }

    describe "Simple Hash Access" do

      def basic_test(id, h, max)
        max.times do |i|
          h["foo-#{id}-#{i}"] = "bar-#{id}-#{i}"

          i.times do |j|
            h["foo-#{id}-#{i}"].should == "bar-#{id}-#{i}"
          end
        end
      end

      it "single-threaded" do
        h = ReadWriteHash.new
        basic_test(1, h, 20)
      end

      it "multi-threaded same-keys" do
        h = ReadWriteHash.new
        10.times do |i|
          Thread.new { basic_test(1, h, 20) }
        end
      end

      it "multi-threaded different-keys" do
        h = ReadWriteHash.new
        10.times do |i|
          Thread.new { basic_test(i, h, 20) }
        end
      end
    end
  end

end
