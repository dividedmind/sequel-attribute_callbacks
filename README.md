# Sequel::AttributeCallbacks

This plugin for Sequel::Record allows to easily hook in callbacks watching 
specific model attribute changes. The hooks are defined with conventionally 
named instance methods for maximum DRYness.

There's special support for callbacks involving array fields (as in Postgres 
array types with :pg_array extension), so that they can be used similarly to 
associations, with add and remove callbacks.

## Installation

Add this line to your application's Gemfile:

    gem 'sequel-attribute_callbacks'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequel-attribute_callbacks

## Synopsis

```ruby
class Person < Sequel::Model
  plugin :attribute_callbacks
  
  def before_name_change old, new_name
    return true unless Dictionary.is_offensive? new_name
  end
  
  def after_name_change old, new
    NameChangeRecord.create self.id, old, new
  end
end
```

Special support for arrays (with pg_array plugin):

```ruby
# widgets table has (colors text[]) column
class Widget < Sequel::Model
  plugin :attribute_callbacks
  
  def before_colors_add color
    return false unless Paint.color_vailable? color
  end
  
  def after_colors_add color
    Paint.order color
  end
  
  def before_colors_remove color
    # this is our company color, we need it!
    return true unless color == 'fuchsia'
  end
  
  def after_colors_remove color
    Paint.reduce_consumption color
  end
end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
