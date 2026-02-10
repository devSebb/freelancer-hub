module ApplicationHelper
  include Pagy::Frontend
  include IconHelper

  # Returns class string for nav pills: 3D active state or inactive state.
  # When path_prefixes is non-empty, active if request.path starts with any prefix.
  # When current_page is set, active if current_page?(current_page).
  def nav_pill_classes(path_prefixes = [], current_page: nil)
    active = if current_page
      current_page?(current_page)
    else
      path_prefixes.any? { |prefix| request.path.start_with?(prefix) }
    end
    active ? "nav-pill-active text-black" : "bg-white/10 text-white hover:bg-white/20"
  end
end
