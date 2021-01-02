require_relative '../test_helper'

module RuntimeProfiler
  class ActiveRecordCallbackTest < Minitest::Test
    def test_should_track_sql_command_in_the_list
      RuntimeProfiler.configure do |config|
        config.profiled_sql_commands = %w[SELECT]
        config.profiled_paths = nil
      end

      callback = Callback::ActiveRecord.new

      queries = [
        'SELECT * FROM users',
        'select id from products'
      ]

      queries.each_with_index do |query, i|
        payload = { sql: query }
        callback.call('xxx', Time.now.to_f, Time.now.to_f, 1, payload)
        assert_equal(i + 1, callback.data.values.count) # number of CALLS of that NOT UNIQUE SQL
      end
    end

    def test_should_not_track_sql_command_not_in_the_list
      RuntimeProfiler.configure do |config|
        config.profiled_sql_commands = %w[INSERT]
        config.profiled_paths = nil
      end
      callback = Callback::ActiveRecord.new

      queries = [
        'SELECT * FROM users',
        'select id from products'
      ]

      queries.each do |query|
        payload = { sql: query }
        callback.call('xxx', Time.now.to_f, Time.now.to_f, 1, payload)
        assert_equal(0, callback.data.values.count) # number of CALLS of that NOT UNIQUE SQL
      end
    end

    def test_query_count_should_be_case_insensitive
      RuntimeProfiler.profiled_sql_commands = %w[INSERT SELECT]

      callback = Callback::ActiveRecord.new

      queries = [
        'SELECT * FROM users',
        'select * from Users'
      ]

      queries.each do |query|
        payload = { sql: query }
        callback.call('xxx', Time.now.to_f, Time.now.to_f, 1, payload)
      end

      assert_equal(1, callback.data.keys.count) # number of UNIQUE SQL
      assert_equal(2, callback.data.values.first[:runtimes].count) # number of CALLS of that UNIQUE SQL
    end

    def test_clean_values_from_where_in_clause
      query = %{
        SELECT * FROM a
        WHERE a.id IN (
          SELECT b.id FROM b WHERE b.id IN (1,2,3,4)
          AND b.uid IN ('aaaa', 'bbbb')
        ) AND a.xid IN (11, 22, 33)
      }
      expected = %{
        SELECT * FROM a
        WHERE a.id IN (
          SELECT b.id FROM b WHERE b.id IN (xxx)
          AND b.uid IN (xxx)
        ) AND a.xid IN (xxx)
      }.squish

      sanitized_sql = sanitized_sql(query)
      assert_equal(expected, sanitized_sql)
    end

    def test_clean_values_from_comparison_operators
      query = %{
        SELECT * FROM a
        WHERE a.id = 1 AND a.uid != 'bbb'
        (a.num > 1 AND a.num < 3) AND
        (start_date >= '2010-01-01' AND end_date <= '2010-10-01') AND
        a.total BETWEEN 0 AND 100 LIMIT 25 OFFSET 0
      }
      expected = %{
        SELECT * FROM a
        WHERE a.id = xxx AND a.uid != xxx
        (a.num > xxx AND a.num < xxx) AND
        (start_date >= xxx AND end_date <= xxx) AND
        a.total BETWEEN xxx AND xxx LIMIT xxx OFFSET xxx
      }.squish

      sanitized_sql = sanitized_sql(query)
      assert_equal(expected, sanitized_sql)
    end

    def test_clean_floating_numbers
      query = %{
        SELECT * FROM a
        WHERE (a.lat BETWEEN 12.4567 AND 38.0678) AND
        (a.lng BETWEEN -70.487 AND -87.790)
      }
      expected = %{
        SELECT * FROM a
        WHERE (a.lat BETWEEN xxx AND xxx) AND
        (a.lng BETWEEN xxx AND xxx)
      }.squish

      sanitized_sql = sanitized_sql(query)
      assert_equal(expected, sanitized_sql)
    end

    def test_clean_sql_query_is_case_insensitive
      query = %{
        SELECT * FROM a
        where a.id = 1 AND a.uid != 'bbb'
        (a.num > 1 AND a.num < 3) AND
        (start_date >= '2010-01-01' AND end_date <= '2010-10-01') AND
        a.total between 0 and 100
      }
      expected = %{
        SELECT * FROM a
        where a.id = xxx AND a.uid != xxx
        (a.num > xxx AND a.num < xxx) AND
        (start_date >= xxx AND end_date <= xxx) AND
        a.total between xxx and xxx
      }.squish

      sanitized_sql = sanitized_sql(query)
      assert_equal(expected, sanitized_sql)
    end

    def test_clean_values
      query = %{
        INSERT INTO users VALUES
        (nextval('id_seq'), 'a', 105, DEFAULT),
        (nextval('id_seq'), 'b', 9100, DEFAULT);
      }
      expected = %{
        INSERT INTO users VALUES (xxx);
      }.squish

      sanitized_sql = sanitized_sql(query)
      assert_equal(expected, sanitized_sql)
    end

    def test_clean_pattern_matching
      query = %(
        SELECT users.* FROM users
        WHERE users.name LIKE '%test%' AND NOT SIMILAR TO '%test ppp'
      )
      expected = %(
        SELECT users.* FROM users
        WHERE users.name LIKE xxx AND NOT SIMILAR TO xxx
      ).squish

      sanitized_sql = sanitized_sql(query)
      assert_equal(expected, sanitized_sql)
    end

    def sanitized_sql(query)
      RuntimeProfiler::SqlEvent
        .new(args: [nil, nil, nil, nil, { sql: query }], trace: [])
        .sanitized_sql
    end
  end
end
