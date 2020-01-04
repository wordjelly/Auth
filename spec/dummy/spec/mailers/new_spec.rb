require "rails_helper"

RSpec.describe New, type: :mailer do
  describe "send_notification" do
    let(:mail) { New.send_notification }

    it "renders the headers" do
      expect(mail.subject).to eq("Send notification")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
