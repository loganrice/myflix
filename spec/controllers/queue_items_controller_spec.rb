require 'spec_helper'

describe QueueItemsController do
  describe "GET index" do
    it "sets @queue_items" do
      karen = Fabricate(:user)
      set_current_user(karen)
      item1 = Fabricate(:queue_item, user: karen)
      item2 = Fabricate(:queue_item, user: karen)
      get :index
      assigns(:queue_items).should match_array([item1, item2])
    end

    it_behaves_like "require_sign_in" do 
      let(:action) { get :index }
    end
  end

  describe "POST create" do
    context "for authenticated users" do
      it "creates a queue item" do
        video = Fabricate(:video)
        set_current_user
        post :create, video_id: video.id
        QueueItem.count.should == 1
      end

      it "associates the queue item to the video" do
        video = Fabricate(:video)
        set_current_user
        post :create, video_id: video.id
        QueueItem.first.video.should == video
      end

      it "associates the queue item with the sign in user" do
        video = Fabricate(:video)
        karen = Fabricate(:user)
        set_current_user(karen)
        post :create, video_id: video.id, user_id: karen.id
        QueueItem.first.user.should == karen
      end
      it "does not add video to queue more than once" do 
        video = Fabricate(:video)
        karen = Fabricate(:user)
        set_current_user(karen)
        Fabricate(:queue_item, video: video, user: karen)
        post :create, video_id: video.id, user_id: karen.id
        karen.queue_items.count.should == 1
      end

      it "adds the last position to queue item" do
        karen = Fabricate(:user)
        set_current_user(karen)
        video1 = Fabricate(:video)
        video2 = Fabricate(:video)
        video3 = Fabricate(:video)
        item1 = Fabricate(:queue_item, video: video1, user: karen)
        item2 = Fabricate(:queue_item, video: video2, user: karen)
        post :create, video_id: video3.id
        queue_item_for_video3 = QueueItem.where(video_id: video3.id, user_id: karen.id).first
        queue_item_for_video3.position.should == 3
      end

      it "redirects to the queue page" do
        video = Fabricate(:video)
        set_current_user
        post :create, video_id: video.id 
        response.should redirect_to my_queue_path
      end

    end

    context "for unauthenticated users" do
      it "does not create a queue item" do
        post :create
        QueueItem.count.should == 0
      end

      it_behaves_like "require_sign_in" do 
        let(:action) { post :create }
      end
    end
  end

  describe "DELETE destroy" do
    it "redirects to the queue page" do
      video = Fabricate(:video)
      karen = Fabricate(:user)
      set_current_user(karen)
      item = Fabricate(:queue_item, video: video, user: karen)
      delete :destroy, id: item.id
      response.should redirect_to my_queue_path
    end

    it "deletes the item from the queue" do
      video = Fabricate(:video)
      karen = Fabricate(:user)
      set_current_user(karen)
      item = Fabricate(:queue_item, video: video, user: karen)
      delete :destroy, id: item.id
      QueueItem.count.should == 0
    end
    it "does not delete the queue item if not in current user queue" do
      video = Fabricate(:video)
      karen = Fabricate(:user)
      bob = Fabricate(:user)
      session[:user_id] = karen.id
      item = Fabricate(:queue_item, video: video, user: bob)
      delete :destroy, id: item.id
      QueueItem.count.should == 1
    end

    it_behaves_like "require_sign_in" do 
      let(:action) { delete :destroy, id: 3 }
    end

    it "normalizes existing queue item positions" do
      karen = Fabricate(:user)
      set_current_user(karen)
      item1 = Fabricate(:queue_item, user: karen, position: 1)
      item2 = Fabricate(:queue_item, user: karen, position: 2)
      delete :destroy, id: item1.id
      QueueItem.first.position.should == 1
    end
  end

  describe "POST update_queue" do
    context "with valid inputs" do
      it "redirects to the queue page" do
        karen = Fabricate(:user)
        set_current_user(karen)
        video = Fabricate(:video)
        item1 = Fabricate(:queue_item, user: karen, position: 1, video: video)
        item2 = Fabricate(:queue_item, user: karen, position: 2, video: video)
        post :update_queue, queue_items: [{id: item1.id, position: 1}, {id: item2.id, position: 2}]
        response.should redirect_to my_queue_path
      end

      it "reorders the queue items" do 
        karen = Fabricate(:user)
        set_current_user(karen)
        item1 = Fabricate(:queue_item, user: karen, position: 1, video: Fabricate(:video))
        item2 = Fabricate(:queue_item, user: karen, position: 3, video: Fabricate(:video))
        item3 = Fabricate(:queue_item, user: karen, position: 2, video: Fabricate(:video))
        post :update_queue, queue_items: [{id: item1.id, position: 1}, {id: item2.id, position: 3}, {id: item3.id, position: 2}]
        karen.queue_items.should == [item1, item3, item2]
      end
      it "normalizes position numbers" do
        karen = Fabricate(:user)
        set_current_user(karen)
        video = Fabricate(:video)
        item1 = Fabricate(:queue_item, user: karen, position: 2, video: video)
        item2 = Fabricate(:queue_item, user: karen, position: 3, video: video)
        post :update_queue, queue_items: [{id: item1.id, position: 2}, {id: item2.id, position: 3}]
        karen.queue_items.map(&:position).should == [1, 2]
      end
    end

    context "with invalid inputs" do
      it_behaves_like "require_sign_in" do 
        let(:action) { post :create }
      end

      it "redirects to queue page if no parameters" do
        karen = Fabricate(:user)
        set_current_user(karen)
        video = Fabricate(:video)
        item1 = Fabricate(:queue_item, user: karen, position: 1, video: video)
        item2 = Fabricate(:queue_item, user: karen, position: 2, video: video)
        post :update_queue, queue_items: [{id: item1.id, position: 1.343}, {id: item2.id, position: 2}]
        response.should redirect_to my_queue_path
      end

      it "sets the flash error message" do
        karen = Fabricate(:user)
        set_current_user(karen)
        video = Fabricate(:video)
        item1 = Fabricate(:queue_item, user: karen, position: 1, video: video)
        post :update_queue, queue_items: [{id: item1.id, position: 1.343}]
        flash[:error].should be_present
      end

      it "does not chang the queue items" do 
        karen = Fabricate(:user)
        set_current_user(karen)
        video = Fabricate(:video)
        item1 = Fabricate(:queue_item, user: karen, position: 1, video: video)
        post :update_queue, queue_items: [{id: item1.id, position: 1.343}]
        karen.queue_items.map(&:position).should == [1]
      end
    end
    context "with unauthenticated users" do
      # it "redirects to sign in page" do
      #   post :update_queue
      #   response.should redirect_to sign_in_path
      # end

      it_behaves_like "require_sign_in" do 
        let(:action) { post :update_queue }
      end

    end

    end
  context "with queue items that do not belong to current user" do
    it "does not change queue items" do
      karen = Fabricate(:user)
      bob = Fabricate(:user)
      set_current_user(karen)
      video = Fabricate(:video)
      item1 = Fabricate(:queue_item, user: karen, position: 1, video: Fabricate(:video))
      item2 = Fabricate(:queue_item, user: bob, position: 2, video: video)
      post :update_queue, queue_items: [{id: item1.id, position: 1}, {id: item2.id, position: 3}]
      item2.reload.position.should == 2
    end
  end
end
