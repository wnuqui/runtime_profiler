# runtime_profiler - Runtime Profiler for Rails Applications [![Build Status](https://wnuqui.semaphoreci.com/badges/runtime_profiler/branches/master.svg?style=shields)](https://wnuqui.semaphoreci.com/projects/runtime_profiler)

`runtime_profiler` instruments API endpoints or methods in your Rails application using Rails' `ActiveSupport::Notifications`

It then aggregates and generates report to give you insights about specific calls in your Rails application.

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

To start profiling, you can make a test and use `RuntimeProfiler.profile!` method in the test. The output of instrumentation will be generated under the `tmp` folder of your application.

Example of a test code wrap by `RuntimeProfiler.profile!` method:
```ruby
it 'updates user' do
  RuntimeProfiler.profile!('updates user', [User]) {
    patch :update, { id: user.id, name: 'Joe' }
  }

  expect(response.status).to eq(200)
end
```

Run tests as usual and follow printed instructions after running tests.

If you prefer writing just a snippet of code, then just wrap the snippet with `RuntimeProfiler.profile!` method:
```ruby
RuntimeProfiler.profile!('UserMailer', [UserMailer]) {
  user = User.last
  UserMailer.with(user: user).weekly_summary.deliver_now
}
```

**Note:** The code (tests or not) where `RuntimeProfiler.profile!` is used must be **free from any mocking** since your goal is to check bottlenecks.

## Viewing Profiling Result

To see profiling/instrumenting report, you can open the report in browser with JSON viewer report. Or you can run the following command:

```bash
bundle exec runtime_profiler view ~/the-rails-app/tmp/runtime-profiling-51079-1521371428.json
```

### view options

Here are the command line options for `runtime_profiler view` command.

```bash
$ bundle exec runtime_profiler view --help

  NAME:

    view

  SYNOPSIS:

    runtime_profiler view <profile.report.json> [options]

  DESCRIPTION:

    Display report in console given the JSON report file

  OPTIONS:

    --sort-by COLUMN
        Sort by COLUMN. COLUMN can be "max_runtime", total_calls" or "total_runtime". Default is "max_runtime".

    --details TYPE
        TYPE can be "full" or "summary". Default is "summary"

    --only-sqls
        Show only SQL queries. Default is false.

    --only-methods
        Show only methods. Default is false.

    --runtime-above RUNTIME
        RUNTIME is integer or float value in ms.

    --calls-above CALLS
        CALLS is integer value.

    --rounding ROUNDING
        ROUNDING is integer value. Used in rounding runtimes. Default is 4.
```

## Configurations

All the configurable variables and their defaults are listed below. These configurations can be put in the `config/initializers` folder of your Rails application.
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