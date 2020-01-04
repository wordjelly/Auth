require 'rails_helper'

RSpec.describe Auth::Workflow::Assembly, type: :model do
  
  context "-- cloning --", :clone => true do
    it "clones recursively" do
      assembly = Auth::Workflow::Assembly.prepare_nested
      cloned_assembly = assembly.clone
      expect(assembly.stages.first.id).not_to eq(cloned_assembly.stages.first.id)
      expect(assembly.stages.first.sops.first.id).not_to eq(cloned_assembly.stages.first.sops.first.id)
      expect(assembly.stages.first.sops.first.steps.first.id).not_to eq(cloned_assembly.stages.first.sops.first.steps.first.id)
    end
  end

end
