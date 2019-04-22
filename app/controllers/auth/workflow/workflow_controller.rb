class Auth::Workflow::WorkflowController < Auth::AuthenticatedController

	before_action :is_admin_user , :only => CONDITIONS_FOR_TOKEN_AUTH

end