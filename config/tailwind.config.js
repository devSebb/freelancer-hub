module.exports = {
  darkMode: 'class',
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/assets/stylesheets/**/*.css',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Poppins', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      colors: {
        // Primary UI green — #94F7AD (matches home/landing)
        accent: {
          DEFAULT: '#94F7AD',
          light: '#B0FAC4',
          dark: '#6EE892',
        },
      },
    },
  },
  plugins: [],
}
