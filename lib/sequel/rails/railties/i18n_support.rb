
module Sequel::Rails::Railties
  module I18nSupport
    # Set the i18n scope to overwrite ActiveModel.
    def i18n_scope
      :sequel
    end
  end
end
