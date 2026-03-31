class ServiceResult
  attr_reader :data, :error_code, :error_message

  def initialize(success:, data: nil, error_code: nil, error_message: nil, duplicate: false)
    @success = success
    @data = data
    @error_code = error_code
    @error_message = error_message
    @duplicate = duplicate
  end

  def self.success(data, duplicate: false)
    new(success: true, data: data, duplicate: duplicate)
  end

  def self.failure(error_code, error_message = error_code.to_s.humanize)
    new(success: false, error_code: error_code, error_message: error_message)
  end

  def success? = @success
  def failure? = !@success
  def duplicate? = @duplicate
end
