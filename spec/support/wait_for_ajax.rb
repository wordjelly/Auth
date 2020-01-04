module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(20) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end
end
