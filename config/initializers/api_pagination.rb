ApiPagination.configure do |config|
  config.page_param do |params|
    params[:page][:number]
  end

  config.per_page_param do |params|
    params[:page][:size]
  end
end
