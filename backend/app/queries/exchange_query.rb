class ExchangeQuery
  def initialize(user, status: nil)
    @user   = user
    @status = status&.to_s
  end

  def call
    scope = Exchange.for_user(@user).recent

    if @status.present? && Exchange.statuses.key?(@status)
      scope = scope.by_status(@status)
    end

    scope
  end
end
