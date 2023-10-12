#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class FilesController < ApplicationController
  layout "project_website"

  after_action :user_track, only: [:index, :show]

  def index
    file_conditions = { "project_id" => @active_project.id, "is_visible" => true }
    file_conditions["is_private"] = false unless @logged_user.member_of_owner?

    sort_type = params[:orderBy]

    if ["filename"].include?(params[:orderBy])
      sort_order = "ASC"
    else
      sort_type = "created_on"
      sort_order = "DESC"
    end

    @current_folder = nil
    @order = sort_type

    respond_to do |format|
      format.html {
        @content_for_sidebar = "index_sidebar"

        @page = params[:page].to_i
        @page = 1 unless @page > 0

        result_set, @files = ProjectFile.find_grouped(sort_type, conditions: file_conditions, page: @page, per_page: Rails.configuration.railscollab.files_per_page, order: "#{sort_type} #{sort_order}")
        @pagination = []
        result_set.total_pages.times { |page| @pagination << page + 1 }

        # Important files and folders (html only)
        @important_files = @active_project.project_files.important
        @important_files = @important_files.is_public unless @logged_user.member_of_owner?
        @folders = @active_project.folders
      }
      format.json {
        @files = ProjectFile.where(file_conditions)
                            .offset(params[:offset])
                            .limit(params[:limit] || Rails.configuration.railscollab.files_per_page)

        render json: @files.to_json(only: [:id,
                                           :filename,
                                           :created_by_id,
                                           :created_on,
                                           :updated_on,
                                           :is_private,
                                           :is_important,
                                           :is_locked,
                                           :comments_count,
                                           :comments_enabled])
      }
    end
  end

  def show
    authorize! :show, @file

    respond_to do |format|
      format.html {
        @revisions = @file.project_file_revisions

        if @revisions.empty?
          error_status(true, :no_file_revisions)
          redirect_back_or_default project_files_path(@active_project)
        end

        @content_for_sidebar = "index_sidebar"
        @pagination = []

        @folder = @file.folder
        @last_revision = @revisions[0]

        @current_folder = @file.folder
        @order = nil
        @page = nil
        @folders = @active_project.folders

        # Important files (html only)
        @important_files = @active_project.project_files.important
        @important_files = @important_files.is_public unless @logged_user.member_of_owner?
      }
      format.json {
        render json: @file.to_json(include: [:project_file_revisions])
      }
    end
  end

  def new
    authorize! :create_file, @active_project

    @file = @active_project.project_files.build()

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @file.to_json }
    end
  end

  def edit
    authorize! :edit, @file
  end

  def create
    authorize! :create_file, @active_project

    file_attribs = file_params
    @file = @active_project.project_files.build(file_attribs)
    @file.created_by = @logged_user

    # verify file data
    file_data = params[:file_data]
    if file_data.nil? or file_data[:file].nil?
      @file.errors.add(:file, I18n.t("required"))
    end

    # sort out other attributes
    @file.filename = file_data[:file] ? (file_data[:file].original_filename).sanitize_filename : nil
    @file.expiration_time = 0
    @file.is_visible = true

    saved = false

    ProjectFile.transaction do
      saved = @file.save

      if saved
        @file.add_revision(file_data[:file], 1, @logged_user, "")
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_file)
          redirect_back_or_default(@file.object_url)
        }

        format.json { render json: @file.to_json, status: :created, location: @file }
      else
        format.html { render action: "new" }

        format.json { render json: @file.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize! :edit, @file

    file_data = params[:file_data]
    unless file_data.nil?
      if file_data[:updated_file] and !file_data[:file]
        @file.errors.add(:file, I18n.t("required"))
      end
    end

    file_attribs = file_params
    @file.attributes = file_attribs
    @file.updated_by = @logged_user
    @file.is_visible = true

    saved = false

    ProjectFile.transaction do
      saved = @file.save

      if saved
        if file_data[:updated_file]
          if file_data[:version_file_change]
            @file.add_revision(file_data[:file], @file.project_file_revisions[0].revision_number + 1, @logged_user, file_data[:revision_comment])
          else
            @file.update_revision(file_data[:file], @file.project_file_revisions[0], @logged_user, file_data[:revision_comment])
          end

          @file.filename = (file_data[:file].original_filename).sanitize_filename
        end
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_edited_file)
          redirect_back_or_default(@file.object_url)
        }

        format.json { head :ok }
      else
        format.html { render action: "edit" }

        format.json { render json: @file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /files/1
  # DELETE /files/1.xml
  def destroy
    authorize! :delete, @file

    @file.updated_by = @logged_user
    @file.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_file)
        redirect_to project_files_url(@active_project)
      }

      format.json { head :ok }
    end
  end

  def download
    revision_id = params[:revision]

    unless revision_id.nil?
      begin
        @file_revision = ProjectFileRevision.where(file_id: @file.id, revision_number: revision_id).first!
      rescue ActiveRecord::RecordNotFound
        error_status(true, :invalid_file_revision)
        redirect_back_or_default project_files_path(@active_project)
        return
      end
    else
      @file_revision = @file.project_file_revisions[0]
    end

    if @file_revision.nil?
      render plain: I18n.t("error_404"), status: 404
      return
    end

    if @file_revision.data.attached?
      redirect_to url_for(@file_revision.data), status: 302
    else
      render plain: I18n.t("error_404"), status: 404
    end
  end

  def attach
    rel_object_type = params[:object_type]
    rel_object_id = params[:object_id]

    if (rel_object_type.nil? or rel_object_id.nil?) or (!["Comment", "Message"].include?(rel_object_type))
      error_status(true, :invalid_request, {}, false)
      redirect_back_or_default project_files_path(@active_project)
      return
    end

    # Find object we want to attach a file to
    begin
      @attach_object = Kernel.const_get(rel_object_type).find(params[:object_id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_object)
      redirect_back_or_default project_files_path(@active_project)
      return
    end

    authorize! :add_file, @attach_object

    case request.request_method_symbol
    when :put
      attach_attribs = params[:attach]

      if attach_attribs[:what] == "new_file"
        begin
          ProjectFile.handle_files(params[:uploaded_files], @attach_object, @logged_user, @attach_object.is_private)
          error_status(false, :success_added_new_file_to_object)
        rescue
          error_status(false, :error_adding_file_to_object)
        end

        redirect_back_or_default @attach_object.object_url
        return
      elsif attach_attribs[:what] == "existing_file"
        begin
          existing_file = @active_project.project_files.find(attach_attribs[:file_id])
        rescue ActiveRecord::RecordNotFound
          error_status(true, :invalid_file)
          redirect_back_or_default @attach_object.object_url
          return
        end

        # Make sure its unique
        does_exist = @attach_object.project_file.any? { |file| file == existing_file }
        if !does_exist
          AttachedFile.create!(created_on: existing_file.created_on,
                               created_by: @logged_user,
                               rel_object: @attach_object,
                               project_file: existing_file)
          #@attach_object.project_file << existing_file
        end

        error_status(false, :success_added_file_to_object)
        redirect_back_or_default @attach_object.object_url
        return
      end

      error_status(true, :error_adding_file_to_object)
      redirect_back_or_default @attach_object.object_url
      return
    end
  end

  def detatch
    # params: manager, file_id, object_id
    rel_object_type = params[:object_type]
    rel_object_id = params[:object_id]

    if (rel_object_type.nil? or rel_object_id.nil?) or (!["Comment", "Message"].include?(rel_object_type))
      error_status(true, :invalid_request, {}, false)
      redirect_back_or_default project_files_path(@active_project)
      return
    end

    # Find object we want to attach a file to
    begin
      @attach_object = Kernel.const_get(rel_object_type).find(params[:object_id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_object)
      redirect_back_or_default project_files_path(@active_project)
      return
    end

    authorize! :add_file, @attach_object

    begin
      existing_file = @active_project.project_files.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_file)
      redirect_back_or_default @attach_object.object_url
      return
    end

    AttachedFile.clear_attachment(@attach_object, existing_file.id)

    error_status(false, :success_removed_file_from_object)
    redirect_back_or_default @attach_object.object_url
  end

  private

  def page_title
    case action_name
    when "index" then @current_folder.nil? ? I18n.t("files") : I18n.t("folder_name", folder: @current_folder.name)
    when "new", "create" then I18n.t("add_file")
    when "edit", "update" then I18n.t("edit_file")
    else super
    end
  end

  def current_tab
    :files
  end

  def current_crumb
    case action_name
    when "index" then :files
    when "attach" then :attach_files
    when "new", "create" then :add_file
    when "edit", "update" then :edit_file
    when "show" then @file.filename
    else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << { title: :files, url: project_files_path(@active_project) } unless action_name == "index"
    crumbs << { title: @folder.name, url: @folder.object_url } if !@folder.nil? and action_name == "show"
    crumbs
  end

  def file_params
    params.require(:file).permit(:tags, :folder_id, :description, :is_private, :is_important, :comments_enabled)
  end

  def load_related_object
    begin
      @file = @active_project.project_files.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_file, {}, false)
      redirect_back_or_default project_files_path(@active_project)
      return false
    end

    return true
  end
end
