# frozen_string_literal: true

# name: community-canned-replies
# about: Add canned replies through the composer for community groups
# version: 1.2
# url: https://github.com/roblox-dev-forum/community-canned-replies

enabled_site_setting :community_canned_replies_enabled

register_asset 'stylesheets/community-canned-replies.scss'

register_svg_icon "far-clipboard" if respond_to?(:register_svg_icon)

after_initialize do

  module ::CommunityCannedReply
    PLUGIN_NAME ||= "community-canned-replies".freeze
    STORE_NAME ||= "replies".freeze

    class Engine < ::Rails::Engine
      engine_name CommunityCannedReply::PLUGIN_NAME
      isolate_namespace CommunityCannedReply
    end
  end

  class CommunityCannedReply::Reply
    class << self

      def add(user_id, title, content)
        id = SecureRandom.hex(16)
        record = { id: id, title: title, content: content }

        replies = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME) || {}

        replies[id] = record
        PluginStore.set(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME, replies)

        record
      end

      def edit(user_id, reply_id, title, content)
        record = { id: reply_id, title: title, content: content }
        remove(user_id, reply_id)

        replies = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME) || {}

        replies[reply_id] = record
        PluginStore.set(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME, replies)

        record
      end

      def all(user_id)
        replies = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME)

        if replies.blank?
          add_default_community_reply
          replies = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME)
        end

        return [] if replies.blank?
        replies.values.sort_by { |reply| reply['title'] || '' }
      end

      def get_reply(user_id, reply_id)
        replies = all(user_id)

        replies.detect { |reply| reply['id'] == reply_id }
      end

      def remove(user_id, reply_id)
        replies = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME)
        replies.delete(reply_id)
        PluginStore.set(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME, replies)
      end

      def use(user_id, reply_id)
        replies = PluginStore.get(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME)
        reply = replies[reply_id]
        reply['usages'] ||= 0
        reply['usages'] += 1
        replies[reply_id] = reply
        PluginStore.set(CommunityCannedReply::PLUGIN_NAME, CommunityCannedReply::STORE_NAME, replies)
      end

      def add_default_community_reply()
        add(1, I18n.t("replies.default_community_reply.title"), I18n.t("replies.default_community_reply.body"))
      end
    end
  end

  require_dependency "application_controller"

  class CommunityCannedReply::CommunityCannedRepliesController < ::ApplicationController
    requires_plugin CommunityCannedReply::PLUGIN_NAME

    before_action :ensure_logged_in
    skip_before_action :check_xhr

    def create
      title   = params.require(:title)
      content = params.require(:content)
      user_id = current_user.id

      record = CommunityCannedReply::Reply.add(user_id, title, content)
      render json: record
    end

    def destroy
      reply_id = params.require(:id)
      user_id  = current_user.id
      record = CommunityCannedReply::Reply.remove(user_id, reply_id)
      render json: record
    end

    def reply
      reply_id = params.require(:id)
      user_id  = current_user.id

      record = CommunityCannedReply::Reply.get_reply(user_id, reply_id)
      render json: record
    end

    def update
      reply_id = params.require(:id)
      title = params.require(:title)
      content = params.require(:content)
      user_id = current_user.id

      record = CommunityCannedReply::Reply.edit(user_id, reply_id, title, content)
      render json: record
    end

    def use
      reply_id = params.require(:id)
      user_id  = current_user.id
      record = CommunityCannedReply::Reply.use(user_id, reply_id)
      render json: record
    end

    def index
      user_id = current_user.id
      replies = CommunityCannedReply::Reply.all(user_id)
      render json: { replies: replies }
    end
  end

  add_to_class(:user, :can_edit_community_canned_replies?) do
    return true if SiteSetting.community_canned_replies_everyone_can_edit
    group_list = SiteSetting.community_canned_replies_groups.split("|").map(&:downcase)
    groups.any? { |group| group_list.include?(group.name.downcase) }
  end

  add_to_class(:user, :can_use_community_canned_replies?) do
    return true if SiteSetting.community_canned_replies_everyone_enabled
    group_list = SiteSetting.community_canned_replies_groups.split("|").map(&:downcase)
    groups.any? { |group| group_list.include?(group.name.downcase) }
  end

  add_to_serializer(:current_user, :can_use_community_canned_replies) do
    object.can_use_community_canned_replies?
  end

  add_to_serializer(:current_user, :can_edit_community_canned_replies) do
    object.can_edit_community_canned_replies?
  end

  require_dependency 'current_user'
  class CommunityCannedRepliesConstraint
    def matches?(request)
      provider = Discourse.current_user_provider.new(request.env)
      if request.get? || request.patch?
        provider.current_user&.can_use_community_canned_replies?
      else
        provider.current_user&.can_edit_community_canned_replies?
      end
    rescue Discourse::InvalidAccess, Discourse::ReadOnly
      false
    end
  end

  CommunityCannedReply::Engine.routes.draw do
    resources :community_canned_replies, path: '/', only: [:index, :create, :destroy, :update] do
      member do
        get "reply"
        patch "use"
      end
    end
  end

  Discourse::Application.routes.append do
    mount ::CommunityCannedReply::Engine, at: "/community_canned_replies", constraints: CommunityCannedRepliesConstraint.new
  end

end
