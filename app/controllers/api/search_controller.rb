class Api::SearchController < ApplicationController
  # GET /search
  def index
    query = params[:query]
    is_private = params[:is_private] == 'true'
    tag_search = params[:tag_search] == 'true'

    user = current_user  # Assuming you have a method to retrieve the current logged-in user
    projects = user.active_projects

    # Perform the search
    @results, @total = if params[:for_user] == 'true'
                         self.class.search_for_user(query, user, {}, tag_search)
                       else
                         self.class.search(query, is_private, projects, {}, tag_search)
                       end

    render json: { results: @results, total: @total }
  end

  def self.search_for_user(query, user, options = {}, tag_search = false)
    search(query, !user.member_of_owner?, user.active_projects, options, tag_search)
  end

  def self.search(query, is_private, projects, options = {}, tag_search = false)
    return [], 0 unless Rails.configuration.railscollab.search_enabled && query.present?

    filters = []
    filters << '(' + projects.map { |pr| "project.id = #{pr.id}" }.join(' OR ') + ')'

    if tag_search
      items = Tag.index.search(query, { filter: filters.join(' AND ') })
    else
      filters << "(is_private = false)" unless is_private
      items = Project.index.search(query, { filter: filters.join(' AND ') })
    end

    item_list = items['hits'].map do |entry|
      Kernel.const_get(entry['class_name'].to_sym).find(entry['id'])
    end.compact

    total = item_list.count
    [item_list, total]
  end
end
