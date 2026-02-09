# frozen_string_literal: true

# Pagy initializer
# See https://ddnexus.github.io/pagy/docs/api/pagy

# Default items per page
Pagy::DEFAULT[:items] = 20

# Use the pagy_*nav helpers
Pagy::DEFAULT[:size] = [ 1, 2, 2, 1 ] # pages around current page

# I18n - Pagy will use Rails I18n automatically
