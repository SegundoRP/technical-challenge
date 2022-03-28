# frozen_string_literal: true

module Api
  module V1
    class UsersController < ApplicationController
      def index
        db_user = User.find_by('login ILIKE ?', user_params )

        conn = Faraday.new('https://api.github.com') do |f|
          f.request :authorization, 'Bearer', Figaro.env.GITHUB_TOKEN
          f.request :json # encode req bodies as JSON
          f.request :retry # retry transient failures
          f.response :follow_redirects # follow redirects
          f.response :json # decode response bodies as JSON
        end

        if db_user.nil?
          response = conn.get("users/#{user_params}")
          response2 = conn.get("users/#{user_params}/repos")
          if response.success? && response2.success?
            user = response.body
            repos = response2.body
            db_user = User.create({ github_id: user['id'], login: user['login'], url: user['html_url'],
                                    name: user['name'], email: user['email'], avatar_url: user['avatar_url'],
                                    repositories: repos })
          else
            db_user = response.body
          end
        end
        render json: db_user.as_json.except('repositories')
      end

      private

      def user_params
        params.require(:username)
      end
    end
  end
end
