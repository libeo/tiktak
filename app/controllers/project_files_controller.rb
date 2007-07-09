# Allow Users to upload/download files, and generate thumbnails where appropriate.
# If it's not an image, try and find an appropriate stock icon
#
class ProjectFilesController < ApplicationController
  require 'RMagick'
#  enable_upload_progress
#  upload_status_for :upload

  def index
    list
    render_action 'list'
  end

  def list
    @project_files = ProjectFile.find(:all, :order => "created_at DESC", :conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND task_id is NULL", session[:user].company.id])
  end

  def show
    @project_files = ProjectFile.find(@params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", session[:user].company.id])

    if @project_files.thumbnail?
      image = Magick::Image.read(@project_files.file_path ).first
      send_data image.to_blob, :filename => @project_files.filename, :type => image.mime_type, :disposition => 'inline'
      GC.start
    else
      send_file @project_files.file_path, :filename => @project_files.filename, :type => "application/octet-stream"
    end
  end

  # Show the thumbnail for a given image
  def thumbnail
    @project_files = ProjectFile.find(@params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", session[:user].company_id])

    if @project_files.thumbnail?
      image = Magick::Image.read( @project_files.thumbnail_path ).first
      send_data image.to_blob, :filename => "thumb_" + @project_files.filename, :type => image.mime_type, :disposition => 'inline'
      GC.start
    end
  end

  def download
    @project_files = ProjectFile.find(@params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", session[:user].company_id])
    send_file @project_files.file_path, :filename => @project_files.filename, :type => "application/octet-stream"
  end


  def new
    if session[:user].projects.nil? || session[:user].projects.size == 0
      redirect_to :controller => 'projects', :action => 'new'
    else
      @project_files = ProjectFile.new
    end
  end

  def upload
    filename = params['project_files']['tmp_file'].original_filename if params['project_files']

    if filename.nil? || filename.strip.length == 0
      flash['notice'] = _('No file selected for upload.')
      redirect_to :action => 'list'
      return
    end


    filename = filename.split("/").last
    filename = filename.split("\\").last

    @params['project_files']['filename'] = filename.gsub(/[^a-zA-Z0-9.]/, '_')

    tmp_file = @params['project_files']['tmp_file']

    @params['project_files'].delete('tmp_file')

    @project_files = ProjectFile.new(@params[:project_files])

    @project_files.company = session[:user].company
    @project_files.customer = @project_files.project.customer

    @project_files.save
    @project_files.reload

    if !File.exist?(@project_files.path) || !File.directory?(@project_files.path)
      File.mkdir(@project_files.path, 0755) rescue begin
                                                   @project_files.destroy
                                                   flash['notice'] = _('Unable to create storage directory.')
                                                   redirect_to :action => 'list'
                                                   return
                                                 end
    end
    File.open(@project_files.file_path, "wb", 0777) { |f| f.write( tmp_file.read ) } rescue begin
                                                                                              @project_files.destroy
                                                                                              flash['notice'] = _("Permission denied while saving file.")
                                                                                              redirect_to :action => 'list'
                                                                                              return
                                                                                            end


    if( File.size?(@project_files.file_path).to_i > 0 )
      @project_files.file_size = File.size?( @project_files.file_path )

      if @project_files.filename[/\.gif|\.png|\.jpg|\.jpeg|\.tif|\.bmp|\.psd/i] && @project_files.file_size > 0
        image = Magick::Image.read( @project_files.file_path ).first

        if image.columns > 0
          @project_files.file_type = ProjectFile::FILETYPE_IMG

          if image.columns > 124 or image.rows > 124

            if image.columns > image.rows
              scale = 124.0 / image.columns
            else
              scale = 124.0 / image.rows
            end

            image.scale!(scale)
          end

          thumb = shadow(image)
          thumb.format = 'jpg'

          t = File.new(@project_files.thumbnail_path, "w", 0777)
          t.write(thumb.to_blob)
          t.close
        end
      end
      GC.start

      if @project_files.file_type != ProjectFile::FILETYPE_IMG
        if @project_files.filename[/\.doc/i]
          @project_files.file_type = ProjectFile::FILETYPE_DOC
        elsif @project_files.filename[/\.txt/i]
          @project_files.file_type = ProjectFile::FILETYPE_TXT
        elsif @project_files.filename[/\.xls|\.sxc|\.csv/i]
          @project_files.file_type = ProjectFile::FILETYPE_XLS
        elsif @project_files.filename[/\.avi|\.mpeg/i]
          @project_files.file_type = ProjectFile::FILETYPE_AVI
        elsif @project_files.filename[/\.mov/i]
          @project_files.file_type = ProjectFile::FILETYPE_MOV
        elsif @project_files.filename[/\.swf/i]
          @project_files.file_type = ProjectFile::FILETYPE_SWF
        elsif @project_files.filename[/\.fla/i]
          @project_files.file_type = ProjectFile::FILETYPE_FLA
        elsif @project_files.filename[/\.xml/i]
          @project_files.file_type = ProjectFile::FILETYPE_XML
        elsif @project_files.filename[/\.html/i]
          @project_files.file_type = ProjectFile::FILETYPE_HTML
        elsif @project_files.filename[/\.css/i]
          @project_files.file_type = ProjectFile::FILETYPE_CSS
        elsif @project_files.filename[/\.zip/i]
          @project_files.file_type = ProjectFile::FILETYPE_ZIP
        elsif @project_files.filename[/\.rar/i]
          @project_files.file_type = ProjectFile::FILETYPE_RAR
        elsif @project_files.filename[/\.tgz/i]
          @project_files.file_type = ProjectFile::FILETYPE_TGZ
        elsif @project_files.filename[/\.mp3|\.wav|\.ogg|\.aiff/i]
          @project_files.file_type = ProjectFile::FILETYPE_AUDIO
        elsif @project_files.filename[/\.iso|\.img/i]
          @project_files.file_type = ProjectFile::FILETYPE_ISO
        elsif @project_files.filename[/\.sql/i]
          @project_files.file_type = ProjectFile::FILETYPE_SQL
        elsif @project_files.filename[/\.asf/i]
          @project_files.file_type = ProjectFile::FILETYPE_ASF
        elsif @project_files.filename[/\.wmv/i]
          @project_files.file_type = ProjectFile::FILETYPE_WMV
        else
          @project_files.file_type = ProjectFile::FILETYPE_UNKNOWN
        end
      end

      if @project_files.save
        flash['notice'] = _('File successfully uploaded.')
        redirect_to :action => 'list'
      else
        render_action 'new'
      end

    else
      flash['notice'] = _('Empty file.')
      redirect_to :action => 'list'
      return
    end

  end

  def edit
    @project_files = ProjectFile.find(@params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", session[:user].company.id])
  end

  def update
    @project_files = ProjectFile.find(@params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", session[:user].company.id])
    if @project_files.update_attributes(@params[:project_files])
      redirect_to :action => 'list'
    else
      render_action 'edit'
    end
  end

  def destroy
    @file = ProjectFile.find(@params[:id], :conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", session[:user].company.id])

    begin
      File.delete(@file.file_path)
      File.delete(@file.thumbnail_path)
    rescue
      flash['notice'] = _("Unable to delete file.")
      redirect_to :action => 'list'
      return
    end
    @file.destroy
    redirect_to :action => 'list'
  end


  def shadow( image )
    w = image.columns
    h = image.rows

    x2 = w + 5
    y2 = h + 5

    # blur margin
    x4 = w + 15
    y4 = h + 15

    c = "White"
    base = Magick::Image.new( x4, y4 ) { self.background_color = c }

    gc = Magick::Draw.new
    gc.fill( "Gray75" )
    gc.rectangle( 5, 5, x2, y2 )
    gc.draw( base )

    # requires RMagick 1.6.1 or later.
    base = base.gaussian_blur_channel( 2, 8, Magick::AllChannels )
    base = base.gaussian_blur_channel( 3, 8, Magick::AllChannels )
    base.composite( image, Magick::NorthWestGravity, Magick::OverCompositeOp )
  end


end
