
module Sequel::Rails
  # Database-backed session store, with a Sequel model as the interface to the
  # session table.
  #
  # Note that Rails will not use this by default (since the default store is
  # CookieStore). To use it, you'll need to add this to config/application.rb:
  #
  #   config.session_store(Sequel::Rails::SessionStore)
  #
  class SessionStore < ActionDispatch::Session::AbstractStore
    class Session < Sequel::Model
      def self.auto_migrate!
        db.create_table :sessions do
          primary_key :id
          column :session_id, String,
                 :null    => false,
                 :unique  => true,
                 :index   => true

          column :data, :text,
                 :null => false

          column :updated_at, DateTime,
                 :null => true,
                 :index => true
        end
      end

      def self.name
        'session'
      end
    end

    SESSION_RECORD_KEY = 'rack.session.record'.freeze

    cattr_accessor :session_class
    self.session_class = Session

  private
    def get_session(env, sid)
      sid ||= generate_sid
      session = find_session(sid)
      env[SESSION_RECORD_KEY] = session
      [ sid, session.data ]
    end

    def set_session(env, sid, session_data)
      session            = get_session_resource(env, sid)
      session.data       = session_data
      session.updated_at = Time.now if session.dirty?
      session.save
    end

    def get_session_resource(env, sid)
      if env[ENV_SESSION_OPTIONS_KEY][:id].nil?
        env[SESSION_RECORD_KEY] = find_session(sid)
      else
        env[SESSION_RECORD_KEY] ||= find_session(sid)
      end
    end

    def find_session(sid)
      klass = self.class.session_class

      klass.where(:session_id => sid).first || klass.new(:session_id => sid)
    end
  end
end
