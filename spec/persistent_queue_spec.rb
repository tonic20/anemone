$:.unshift(File.dirname(__FILE__))
require 'spec_helper'

module Anemone
  
  class PersistentQueue
    def que
      @que
    end
  end

  describe PersistentQueue do
    
    it "should be subclass of Queue" do
      Anemone::PersistentQueue.new.is_a?(Queue).should == true
    end
    
    it "should receive queue storage as argument in the constructor" do      
      pq = Anemone::PersistentQueue.new []
      pq.que.should be_an_instance_of(Array)
    end

    it "should set Array as the default storage" do
      Anemone::PersistentQueue.new.que.should be_an_instance_of(Array)
    end
    
  end
end