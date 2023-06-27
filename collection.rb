# Benchmark script to run varieties of JSON serializers
# Fetch Alba from local, otherwise fetch latest from RubyGems

require_relative 'prep'

# --- jsonapi serializer ---
require "jsonapi/serializer"

class JsonApiCommentResource
  include JSONAPI::Serializer
  set_type :comments
  attributes :id, :body
end

class JsonApiPostResource
  include JSONAPI::Serializer
  set_type :post
  attributes :id, :body
  attribute :commenter_names do |post|
    post.commenters.pluck(:name)
  end
  has_many :comments, serializer: JsonApiCommentResource
end

# --- Alba serializers ---

require "alba"

class AlbaCommentResource
  include ::Alba::Resource
  attributes :id, :body
end

class AlbaPostResource
  include ::Alba::Resource
  attributes :id, :body
  attribute :commenter_names do |post|
    post.commenters.pluck(:name)
  end
  many :comments, resource: AlbaCommentResource
end

# --- ActiveModelSerializer serializers ---

require "active_model_serializers"

# ActiveModelSerializers.logger = Logger.new(nil)

class AMSCommentSerializer < ActiveModel::Serializer
  attributes :id, :body
end

class AMSPostSerializer < ActiveModel::Serializer
  attributes :id, :body, :commenter_names
  # attributes :id, :body
  # attribute :commenter_names
  has_many :comments, serializer: AMSCommentSerializer

  def commenter_names
    object.commenters.pluck(:name)
  end
end

# --- Blueprint serializers ---

require "blueprinter"

class CommentBlueprint < Blueprinter::Base
  fields :id, :body
end

class PostBlueprint < Blueprinter::Base
  fields :id, :body, :commenter_names
  association :comments, blueprint: CommentBlueprint

  def commenter_names
    commenters.pluck(:name)
  end
end

# --- Jserializer serializers ---

require 'jserializer'

class JserializerCommentSerializer < Jserializer::Base
  attributes :id, :body
end

class JserializerPostSerializer < Jserializer::Base
  attributes :id, :body, :commenter_names
  has_many :comments, serializer: JserializerCommentSerializer

  def commenter_names
    object.commenters.pluck(:name)
  end
end

# --- Panko serializers ---
#

require "panko_serializer"

class PankoCommentSerializer < Panko::Serializer
  attributes :id, :body
end

class PankoPostSerializer < Panko::Serializer
  attributes :id, :body, :commenter_names

  has_many :comments, serializer: PankoCommentSerializer

  def commenter_names
    object.commenters.pluck(:name)
  end
end

# --- Representable serializers ---

require "representable"

class CommentRepresenter < Representable::Decorator
  include Representable::JSON

  property :id
  property :body
end

class PostsRepresenter < Representable::Decorator
  include Representable::JSON::Collection

  items class: Post do
    property :id
    property :body
    property :commenter_names
    collection :comments
  end

  def commenter_names
    commenters.pluck(:name)
  end
end

# --- SimpleAMS serializers ---

require "simple_ams"

class SimpleAMSCommentSerializer
  include SimpleAMS::DSL

  attributes :id, :body
end

class SimpleAMSPostSerializer
  include SimpleAMS::DSL

  attributes :id, :body
  attribute :commenter_names
  has_many :comments, serializer: SimpleAMSCommentSerializer

  def commenter_names
    object.commenters.pluck(:name)
  end
end

require 'turbostreamer'
TurboStreamer.set_default_encoder(:json, :oj)

class TurbostreamerSerializer
  def initialize(posts)
    @posts = posts
  end

  def to_json
    TurboStreamer.encode do |json|
      json.array! @posts do |post|
        json.object! do
          json.extract! post, :id, :body, :commenter_names

          json.comments post.comments do |comment|
            json.object! do
              json.extract! comment, :id, :body
            end
          end
        end
      end
    end
  end
end

# --- Test data creation ---

100.times do |i|
  post = Post.create!(body: "post#{i}")
  user1 = User.create!(name: "John#{i}")
  user2 = User.create!(name: "Jane#{i}")
  10.times do |n|
    post.comments.create!(commenter: user1, body: "Comment1_#{i}_#{n}")
    post.comments.create!(commenter: user2, body: "Comment2_#{i}_#{n}")
  end
end

posts = Post.all.includes(:comments, :commenters)

# --- Store the serializers in procs ---

alba = Proc.new { AlbaPostResource.new(posts).serialize }
alba_inline = Proc.new do
  Alba.serialize(posts) do
    attributes :id, :body
    attribute :commenter_names do |post|
      post.commenters.pluck(:name)
    end
    many :comments do
      attributes :id, :body
    end
  end
end

# ams = Proc.new { ActiveModelSerializers::SerializableResource.new(posts, {each_serializer: AMSPostSerializer}).to_json }
ams = Proc.new { ActiveModel::ArraySerializer.new(posts, each_serializer: AMSPostSerializer).to_json }
blueprinter = Proc.new { PostBlueprint.render(posts) }
jserializer = Proc.new { JserializerPostSerializer.new(posts, is_collection: true).to_json }
panko = proc { Panko::ArraySerializer.new(posts, each_serializer: PankoPostSerializer).to_json }
json_api = proc { JsonApiPostResource.new(posts, { include: [:comments] }).serializable_hash.to_json }
rails = Proc.new do
  ActiveSupport::JSON.encode(posts.map { |post| post.serializable_hash(include: :comments) })
end
representable = Proc.new { PostsRepresenter.new(posts).to_json }
simple_ams = Proc.new { SimpleAMS::Renderer::Collection.new(posts, serializer: SimpleAMSPostSerializer).to_json }
turbostreamer = Proc.new { TurbostreamerSerializer.new(posts).to_json }

# --- Execute the serializers to check their output ---
GC.disable
puts "Checking outputs..."
correct = alba.call
parsed_correct = JSON.parse(correct)
{
  alba_inline: alba_inline,
  ams: ams,
  blueprinter: blueprinter,
  jserializer: jserializer,
  panko: panko,
  json_api: json_api,
  rails: rails,
  representable: representable,
  simple_ams: simple_ams,
  turbostreamer: turbostreamer
}.each do |name, serializer|
  result = serializer.call
  parsed_result = JSON.parse(result)
  puts "#{name} yields wrong output: #{parsed_result}" unless parsed_result == parsed_correct
end

# --- Run the benchmarks ---

require 'benchmark/ips'
Benchmark.ips do |x|
  x.report(:alba, &alba)
  x.report(:alba_inline, &alba_inline)
  x.report(:ams, &ams)
  x.report(:blueprinter, &blueprinter)
  x.report(:jserializer, &jserializer)
  x.report(:panko, &panko)
  x.report(:json_api, &json_api)
  x.report(:rails, &rails)
  x.report(:representable, &representable)
  x.report(:simple_ams, &simple_ams)
  x.report(:turbostreamer, &turbostreamer)

  x.compare!
end

require 'benchmark/memory'
Benchmark.memory do |x|
  x.report(:alba, &alba)
  x.report(:alba_inline, &alba_inline)
  x.report(:ams, &ams)
  x.report(:blueprinter, &blueprinter)
  x.report(:jserializer, &jserializer)
  x.report(:panko, &panko)
  x.report(:json_api, &json_api)
  x.report(:rails, &rails)
  x.report(:representable, &representable)
  x.report(:simple_ams, &simple_ams)
  x.report(:turbostreamer, &turbostreamer)

  x.compare!
end
