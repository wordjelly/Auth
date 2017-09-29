=begin
require 'aws-sdk'
Aws.config.update({ 
  region:      "eu-west-1",
  credentials: Aws::Credentials.new("AKIAJXE7NYZBKHOJPETA", "kFq/M56jgvxNYKBeCxZnxOOlgE2aWDXhqI0yb8+8")
})


sqs = Aws::SQS::Client.new(
  region:      "eu-west-1",
  credentials: Aws::Credentials.new("AKIAJXE7NYZBKHOJPETA", "kFq/M56jgvxNYKBeCxZnxOOlgE2aWDXhqI0yb8+8")
)
#l = sqs.create_queue({queue_name: 'default'})
#puts l.to_s
=end