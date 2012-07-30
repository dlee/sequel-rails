
Sequel::Database.class_eval do
  # Override #log_yield so that if `config.sequel.truncate_sql_to` was specified
  # in config/application.rb, when the SQL is query is logged, truncate it to
  # the length. Also, if the query contains any line breaks, convert them to
  # "\n".
  #
  def log_yield(sql, args=nil)
    return yield if @loggers.empty?
    sql = sql.gsub(/\n/, "\\n")
    if len = Sequel::Rails.configuration.sql_truncate_length and sql.length > len
      sql = sql[0...len] + '...'
    end
    sql = "#{sql}; #{args.inspect}" if args
    start = Time.now
    begin
      yield
    rescue => e
      log_each(:error, "#{e.class}: #{e.message.strip}: #{sql}")
      raise
    ensure
      log_duration(Time.now - start, sql) unless e
    end
  end
end
