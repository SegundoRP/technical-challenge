# frozen_string_literal: true

module Api
  module V1
    class RepositoriesController < ApplicationController
      def index
        conn = Faraday.new do |f|
          f.request :authorization, 'Bearer', Figaro.env.GITHUB_TOKEN
          f.request :json # encode req bodies as JSON
          f.request :retry # retry transient failures
          f.response :follow_redirects # follow redirects
          f.response :json # decode response bodies as JSON
        end
        user = conn.get("https://api.github.com/users/#{user_params}").body
        repos = conn.get("https://api.github.com/users/#{user_params}/repos",
                         { per_page: 100, sort: 'updated' }).body
        db_user = User.all.find { |u| u.github_id == user['id'] }
        if db_user.nil?
          db_user = User.create({ github_id: user['id'], login: user['login'], url: user['html_url'], name: user['name'],
                                  email: user['email'], avatar_url: user['avatar_url'], repositories: repos })
        end
        render json: db_user.repositories
      end

      def search
        conn = Faraday.new do |f|
          f.request :authorization, 'Bearer', Figaro.env.GITHUB_TOKEN
          f.request :json # encode req bodies as JSON
          f.request :retry # retry transient failures
          f.response :follow_redirects # follow redirects
          f.response :json # decode response bodies as JSON
        end
        user = conn.get("https://api.github.com/users/#{user_params}").body
        repos = conn.get("https://api.github.com/users/#{user_params}/repos", { per_page: 100, sort: 'updated' }).body
        db_user = User.all.find { |u| u.github_id == user['id'] }

        if db_user.nil?
          db_user = User.create({ github_id: user['id'], login: user['login'], url: user['html_url'], name: user['name'],
                                  email: user['email'], avatar_url: user['avatar_url'], repositories: repos })
          if params[:query].empty?
            render json: db_user.repositories
          else
            repository = db_user.repositories.select { |repo| repo['name'] == params[:query] }
            render json: repository
          end
        else
          if params[:query].empty?
            render json: db_user.repositories
          else
            repository = db_user.repositories.select { |repo| repo['name'] == params[:query] }
            render json: repository
          end
        end
      end

      private

      def user_params
        params.require(:user_id)
      end

      def search_action

      end
    end
  end
end
