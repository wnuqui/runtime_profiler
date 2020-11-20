# runtime_profiler - Runtime Profiler for Rails Applications [![Build Status](https://wnuqui.semaphoreci.com/badges/runtime_profiler/branches/master.svg?style=shields)](https://wnuqui.semaphoreci.com/projects/runtime_profiler)

`runtime_profiler` instruments api or a method of your Rails application using Rails' `ActiveSupport::Notifications`

It then aggregates and generates report to give you insights about specific calls in your Rails application.

## Note

This is still a **work in progress**. However, this is a tool meant to be used in development so it is safe to use.

## Installation

Add this line to your application's Gemfile:

```ruby
group :development, :test do
  ... ...
  gem 'runtime_profiler'
end
```

And then execute:

    $ bundle

## Profiling/Instrumenting

To start profiling, make a test and use `RuntimeProfiler.profile!` method in the tests. The output of instrumentation will be generated under the `tmp` folder of your application.

Example:
```ruby
it 'updates user' do
  RuntimeProfiler.profile!('updates user', [User]) {
    patch :update, { id: user.id, name: 'Joe' }
  }

  expect(response.status).to eq(200)
end
```

Run tests as usual and follow printed instructions after running tests.

## Reporting

To see profiling/instrumenting report, please open the report in browser with JSON viewer report. Or you can run the following command:

```bash
bundle exec runtime_profiler view ~/the-rails-app/tmp/runtime-profiling-51079-1521371428.json
```

## Configurations

All the configurable variables and their defaults are listed below:
```ruby
RuntimeProfiler.output_path = File.join(Rails.root.to_s, 'tmp')
RuntimeProfiler.instrumented_constants = [User]
RuntimeProfiler.instrumented_paths = %w(app lib)
RuntimeProfiler.instrumented_sql_commands = %w(SELECT INSERT UPDATE DELETE)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wnuqui/runtime_profiler. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Acknowledgement

Part of this profiler is based from https://github.com/steventen/sql_tracker.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).