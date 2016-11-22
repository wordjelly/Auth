require 'rails_helper'

RSpec.describe "topics/new", type: :view do
  before(:each) do
    assign(:topic, Topic.new(
      :name => "MyText",
      :place => "MyText"
    ))
  end

  it "renders new topic form" do
    render

    assert_select "form[action=?][method=?]", topics_path, "post" do

      assert_select "textarea#topic_name[name=?]", "topic[name]"

      assert_select "textarea#topic_place[name=?]", "topic[place]"
    end
  end
end
