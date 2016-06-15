module Auth
  class ApplicationController < DeviseController
    protect_from_forgery with: :exception
  end
end
