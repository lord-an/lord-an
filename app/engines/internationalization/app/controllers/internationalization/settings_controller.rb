module Internationalization
  class SettingsController < ApplicationController
    def show
      redirect_to "/settings#language"
    end
  end
end
