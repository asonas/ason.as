/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./source/**/*.{html,js,haml,erb,rb}",
    "./articles/**/*.md",
    "./source/layouts/**/*.haml",
    "./source/articles/**/*.haml"
  ],
  theme: {
    extend: {
      colors: {
        // 旧バージョンのグレースケールを再現
        gray: {
          50: '#f9fafb',
          100: '#f3f4f6',
          200: '#e5e7eb',
          300: '#d1d5db',
          400: '#9ca3af',
          500: '#6b7280',
          600: '#4b5563',
          700: '#374151',
          800: '#1f2937',
          900: '#111827',
        },
        blue: {
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
        },
      },
    },
  },
  plugins: [],
}
