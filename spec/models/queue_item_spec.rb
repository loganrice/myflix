require 'spec_helper'

describe QueueItem do
  it { should belong_to(:user) }
  it { should belong_to(:video) }
  it { should validate_numericality_of(:position).only_integer }
  
  describe "#video_title" do
    it "returns the title of the associated videos" do
      video = Fabricate(:video, title: 'Monk')
      queue_item = Fabricate(:queue_item, video: video)
      queue_item.video_title.should == 'Monk'
    end
  end

  describe "#rating" do 
    it "returns the rating from the review when present" do 
      video = Fabricate(:video)
      user = Fabricate(:user)
      review = Fabricate(:review, user: user, video: video, rating: 4)
      queue_item = Fabricate(:queue_item, user: user, video: video)
      queue_item.rating.should == 4
    end
    it "returns nil when no review present" do
      video = Fabricate(:video)
      user = Fabricate(:user)
      queue_item = Fabricate(:queue_item, user: user, video: video)
      queue_item.rating.should == nil      
    end
  end

  describe "#rating=" do
    it "changes rating of the review if the review is present" do
      video = Fabricate(:video)
      karen = Fabricate(:user)
      review = Fabricate(:review, user: karen, video: video, rating: 2)
      queue_item = Fabricate(:queue_item, user: karen, video: video)
      queue_item.rating = 4
      Review.first.rating.should == 4
    end
    it "clears the rating of the review if the review is present" do
      video = Fabricate(:video)
      karen = Fabricate(:user)
      review = Fabricate(:review, user: karen, video: video, rating: 2)
      queue_item = Fabricate(:queue_item, user: karen, video: video)
      queue_item.rating = nil
      Review.first.rating.should == nil
    end

    it "creates a review with rating if review is not present" do
      video = Fabricate(:video)
      karen = Fabricate(:user)
      queue_item = Fabricate(:queue_item, user: karen, video: video)
      queue_item.rating = 3
      Review.first.rating.should == 3
    end
  end

  describe "#category_name" do 
    it "returns the category's name of the video" do
      category = Fabricate(:category, name: "comedies")
      video = Fabricate(:video, category: category)
      queue_item = Fabricate(:queue_item, video: video)
      queue_item.category_name.should == "comedies"
    end
  end

  describe "#category" do
    it "returns the category of the video" do
      category = Fabricate(:category, name: "comedies")
      video = Fabricate(:video, category: category)
      queue_item = Fabricate(:queue_item, video: video)
      queue_item.category.should == category 
    end
  end
end