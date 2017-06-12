# PROJECT_NAMEはprojects/project_id/models/モデル名の形

require "rest_client"

class PredictForm
  include ActiveModel::Model
  IMG_COL = 64
  IMG_ROW = 64
  IMG_CHANNEL = 3
  URL = "https://ml.googleapis.com/v1beta1/#{ENV["PROJECT_NAME"]}:predict".freeze
  SCOPE = ["https://www.googleapis.com/auth/cloud-platform"].freeze
  @@token = ""

  attr_accessor :file, :image, :matrix_data, :result

  validates :file, presence: true

  def predict
    begin
      self.result = RestClient.post(URL, file_to_json, header)
    rescue RestClient::Unauthorized => e
      p e
      refresh_token

      unless @refreshed
        self.predict
        @refreshed = true
      end
    end
  end

  def file_to_json
    file_resize
    file_to_matrix
    to_json
  end

  def refresh_token
   @@token = Google::Auth::ServiceAccountCredentials.make_creds(
               json_key_io: json_key_io,
               scope: SCOPE).fetch_access_token!["access_token"]
  end

  def header
    { Authorization: "Bearer #{@@token}",  content_type: :json }
  end

  def resized_image
    image.resize(IMG_ROW, IMG_COL)
  end

  private

  def url
    "https://ml.googleapis.com/v1beta1/#{ENV["PROJECT_NAME"]}:predict"
  end

  def file_resize
    self.image = Magick::ImageList.new(file.tempfile.path)
  end

  def file_to_matrix
    self.matrix_data = resized_image.export_pixels.map {|p| p / 257 }
                                    .each_slice(IMG_CHANNEL)
                                    .each_slice(IMG_ROW).to_a
  end

  def to_json
    {"instances": {"inputs": matrix_data}}.to_json
  end

  def json_key_io
    @json_key_io = OpenStruct.new
    @json_key_io.read =
      {"private_key": ENV["GOOGLE_PRIVATE_KEY"].gsub("\\n", "\n"), "client_email": ENV["GOOGLE_CLIENT_EMAIL"].gsub("\\n", "\n")}.to_json
    @json_key_io
  end
end

