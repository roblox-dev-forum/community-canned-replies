# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommunityCannedReply::CommunityCannedRepliesController do
  let(:privileged_group) do
    group = Fabricate(:group, users: [privileged_user])
    group.add(privileged_user)
    group.save
    group
  end

  let(:privileged_user) do
    user = Fabricate(:user)
    sign_in(user)
    user
  end

  let(:user) do
    user = Fabricate(:user)
    sign_in(user)
    user
  end

  let(:community_canned_reply) { CommunityCannedReply::Reply.add(privileged_user, 'some title', 'some content') }

  describe 'listing community canned replies' do
    context 'as a normal user' do
      it 'should raise the right error' do
        user

        get '/community_canned_replies'
        expect(response.status).to eq(404)
      end
    end

    context 'as a normal user with everyone enabled' do
      it 'should not raise an error' do
        SiteSetting.community_canned_replies_everyone_enabled = true
        user

        get '/community_canned_replies'
        expect(response.status).to eq(200)
      end
    end

    let(:list_community_canned_replies) do
      post '/community_canned_replies', params: {
        title: 'Reply test title', content: 'Reply test content'
      }

      expect(response).to be_successful

      get '/community_canned_replies'

      expect(response).to be_successful

      replies = JSON.parse(response.body)["replies"]
      reply = replies.first

      expect(replies.length).to eq(1)
      expect(reply['title']).to eq 'Reply test title'
      expect(reply['content']).to eq 'Reply test content'
    end

    context 'as a privileged user' do

      before do
        privileged_user
        privileged_group
        SiteSetting.community_canned_replies_groups = privileged_group.name
      end

      it "should list all replies correctly" do
        list_community_canned_replies
      end
    end
  end

  describe 'removing community canned replies' do
    context 'as a normal user' do
      it 'should raise the right error' do
        user

        delete '/community_canned_replies/someid'
        expect(response.status).to eq(404)
      end

      it 'should raise the right error with everyone enabled' do
        SiteSetting.community_canned_replies_everyone_enabled = true
        user

        delete '/community_canned_replies/someid'
        expect(response.status).to eq(404)
      end
    end

    let(:remove_community_canned_replies) do
      post '/community_canned_replies', params: {
        title: 'Reply test title', content: 'Reply test content'
      }

      expect(response).to be_successful

      id, _new_reply = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME).first

      delete "/community_canned_replies/#{id}"

      expect(response).to be_successful
      expect(PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME)).to eq({})
    end

    context 'as a privileged user' do

      before do
        privileged_user
        privileged_group
        SiteSetting.community_canned_replies_groups = privileged_group.name
      end

      it 'should be able to remove reply' do
        remove_community_canned_replies
      end
    end

    context 'as a regular user with everyone can edit enabled' do
      it 'should be able to remove reply' do
        SiteSetting.community_canned_replies_everyone_enabled = true
        SiteSetting.community_canned_replies_everyone_can_edit = true
        user

        remove_community_canned_replies
      end
    end
  end

  describe 'editing a community canned reply' do
    context 'as a normal user' do
      it 'should raise the right error' do
        user

        put '/community_canned_replies/someid'
        expect(response.status).to eq(404)
      end
      it 'should raise the right error with everyone enabled' do
        SiteSetting.community_canned_replies_everyone_enabled = true
        user

        put '/community_canned_replies/someid'
        expect(response.status).to eq(404)
      end
    end

    let(:edit_community_canned_reply) do
      post '/community_canned_replies', params: {
        title: 'Reply test title', content: 'Reply test content'
      }

      expect(response).to be_successful

      id, _new_reply = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME).first

      put "/community_canned_replies/#{id}", params: {
        title: 'new title', content: 'new content'
      }

      expect(response).to be_successful

      id, reply = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME).first

      expect(reply["title"]).to eq('new title')
      expect(reply["content"]).to eq('new content')
    end

    context 'as a privileged user' do

      before do
        privileged_user
        privileged_group
        SiteSetting.community_canned_replies_groups = privileged_group.name
      end

      it 'should be able to edit a reply' do
        edit_community_canned_reply
      end
    end
    context 'as a regular user with everyone can edit enabled' do
      it 'should be able to edit a reply' do
        SiteSetting.community_canned_replies_everyone_enabled = true
        SiteSetting.community_canned_replies_everyone_can_edit = true
        user

        edit_community_canned_reply
      end
    end
  end

  describe 'recording canned replies usages' do
    context 'as a normal user' do
      it 'should raise the right error' do
        community_canned_reply
        user

        patch "/community_canned_replies/#{community_canned_reply[:id]}/use"
        expect(response.status).to eq(404)
      end

      it 'should be able to record a user with everyone enabled' do
        SiteSetting.community_canned_replies_everyone_enabled = true
        community_canned_reply
        user

        patch "/community_canned_replies/#{community_canned_reply[:id]}/use"
        expect(response).to be_successful
        _id, reply = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME).first

        expect(reply["usages"]).to eq(1)
      end
    end
  end

  describe 'retrieving a community canned reply' do
    context 'as a normal user' do
      it 'should raise the right error' do
        community_canned_reply
        user

        get "/community_canned_replies/#{community_canned_reply[:id]}/reply"
        expect(response.status).to eq(404)
      end
      it 'should succeed with everyone enabled' do
        SiteSetting.community_canned_replies_everyone_enabled = true
        community_canned_reply
        user

        get "/community_canned_replies/#{community_canned_reply[:id]}/reply"
        expect(response).to be_successful
      end
    end
  end
end
