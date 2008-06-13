class Image < Attachment
  
  #Override Attachment settings for images
  has_attachment :content_type => :image,
                 :storage => :file_system, 
                 :max_size => 1.megabytes
                 #:thumbnails => { :thumb => '100x100>' }

  #validates_as_attachment
  #Custom validation messages
  validates_attachment :empty => "You forgot to select a file to upload, or the selected file had no contents.",
                       :size  => "The file you uploaded was larger than the maximum size of 1MB.",
                       :content_type => "Please upload an image file (JPEG, PNG or GIF)."
  

  #By default, BibApp doesn't perform any image resizing or thumbnail creation.
  # For image resizing or thumbnail creation, you will have to do some modifications
  # to this Image model and the Attachment controllers/views.  For more info on 
  # setting up image resizing or thumbnails, see this great attachment_fu tutorial:
  #   http://clarkware.com/cgi/blosxom/2007/02/24#FileUploadFu
end
