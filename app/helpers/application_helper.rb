module ApplicationHelper
  
  def title
    base_title = "Fantasy Sports Book"
    if @page_title.nil?
      base_title
    else
      "#{base_title} | #{@page_title}"
    end
  end
  
end
