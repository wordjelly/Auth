require 'rails_helper'

RSpec.describe "topics/edit", type: :view do
  before(:each) do
    @topic = assign(:topic, Topic.create!(
      :name => "MyText",
      :place => "MyText"
    ))
  end

  it "renders the edit topic form" do
    render

    assert_select "form[action=?][method=?]", topic_path(@topic), "post" do

      assert_select "textarea#topic_name[name=?]", "topic[name]"

      assert_select "textarea#topic_place[name=?]", "topic[place]"
    end
  end
end
