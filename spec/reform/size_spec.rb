
require_relative '../../lib/reform/object'

include R

[Qt::Size, Qt::SizeF
].each do |qtsize|
  describe qtsize do
    it "can be constructed in some ways" do
      #tag "i = #{i}"
      # without parameters, an empty and invalid size is created
      o = qtsize.new
      o.should_not be_valid
      o.should be_empty
      o = qtsize.new 24
      o.width.should == 24
      o.height.should == 24
      o = qtsize.new 24, 35
      # extension to Qt: aliases 'w' and 'h'. Cause I'm lazy you know...
      o.w.should == 24
      o.h.should == 35
      o.should be_valid
      o = qtsize.new [24, 35]
      o.w.should == 24
    end

    it "can be null and empty" do
      o = qtsize.new 24, 35
      o.should_not be_empty
      o.should_not be_null
      o = qtsize.new 24, 0
      o.should be_empty
      o.should_not be_null
      # null? is only true if both values are 0
      o = qtsize.new 0, 0
      o.should be_valid
      o.should be_empty
      o.should be_null
      # invalid ones are also empty
      o = qtsize.new -1, 0
      o.should_not be_valid
      o.should be_empty
      o.should_not be_null
    end

    it "can be modified" do
      sz = qtsize.new 1, 4
      sz.w = 5
      sz.w.should == 5
      sz.h = 2
      sz.h.should == 2
      # assign accepts any arg the constructor does too
      sz.assign 3
      sz.w.should == 3
      sz.h.should == 3
      sz.assign 3, 4
      sz.w.should == 3
      sz.h.should == 4
      sz.assign
      sz.should_not be_valid
      sz.assign [3, 4]
      sz.w.should == 3
      sz.h.should == 4
    end

    it "can be compared" do
      #tag "can be compared"
      sz = qtsize.new 1, 4
      #tag "compare w ary"
      sz.should == [1, 4] 
      #tag "compare w another qtsize"
      sz.should == qtsize.new(1, 4)
      sz = qtsize.new 1, 1
      #tag "compare w square"
      sz.should == 1
      # are invalid ones equal?
      sz1 = qtsize.new
      sz2 = qtsize.new
      sz1.should == sz2
      sz2 = qtsize.new -2, -2
      #tag "comparing two 'invalids'"
      # Qt sees them different. It really compares the contents here too.
      sz1.should_not == sz2
    end

    it "can be added and substracted" do
      sz1 = qtsize.new 1, 4
      sz1 += [3, 2]
      sz1.to_a.should == [4, 6]
      sz1 -= qtsize.new 1
      # to_a is really not required
      sz1.should == [3, 5]
    end

    it "can be scaled" do
      sz = qtsize.new 2, 4
      sz *= 2
      sz.should == [4, 8]
      sz /= 4
      sz.should == [1, 2]
      t = qtsize.new 10, 12
      # Qt has scale + scaled.
      # I have scale! + scale
      t.scale(60, :ignoreAspectRatio).should == [60, 60]
      t.scale(60, :keepAspectRatio).should == [50, 60]
      t.should == [10, 12]
      t.scale(60, :keepAspectRatioByExpanding).should == [60, 72]
    end

    it "can be transposed (swap w/h)" do
      sz = qtsize.new 2, 4
      sz.transpose.should == [4, 2]
      sz.should == [2, 4]
      sz.transpose!.should == [4, 2]
      sz.should == [4, 2]
    end

    it "can be bounded and expanded" do
      sz1 = qtsize.new 2, 4
      sz2 = qtsize.new 3, 3
      (sz1 & sz2).should == [2, 3]
      (sz1 | sz2).should == [3, 4]
    end
  end
end
