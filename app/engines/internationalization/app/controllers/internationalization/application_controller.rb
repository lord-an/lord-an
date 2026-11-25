module Internationalization
  class ApplicationController < ActionController::Base
    layout "application"

    include Locale
  end
end
