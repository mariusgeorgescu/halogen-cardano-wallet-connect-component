/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./index.js"
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: ["dim"],
  },
  // Safelist all dynamic classes to prevent purging
  safelist: [
    // Badge colors from badgeColor function
    'badge-info',
    'badge-error', 
    'badge-success',
    'badge-warning',
    'badge-neutral',
    'badge-primary',
    'badge-secondary',
    'badge-accent',

    // Button colors from buttonType and buttonColour
    'btn-primary',
    'btn-secondary',
    'btn-accent',
    'btn-error',
    'btn-ghost',

    // Alert colors from alertType
    'alert-info',
    'alert-success', 
    'alert-warning',
    'alert-error',

    // Input colors from inputColor
    'input-secondary',
    'input-error',

    // Divider colors from deviderType
    'divider-primary',
    'divider-secondary',
    'divider-accent',
    'divider-neutral',
    'divider-default',

    // Text colors from textColor and milestoneState
    'text-success',
    'text-warning',
    'text-error', 
    'text-info',
    'text-primary-content',
    'text-secondary-content',
    'text-neutral-content',

    // Background colors from bg- patterns
    'bg-success',
    'bg-warning',
    'bg-error',
    'bg-info',
    'bg-primary',
    'bg-secondary',
    'bg-neutral',

    // Timeline colors from lineColor
    'bg-success',
    'bg-warning', 
    'bg-error',
    'bg-info',

    // Timeline box text colors
    'text-success',
    'text-warning',
    'text-error',
    'text-info',

    // Radial progress colors
    'text-success',
    'text-warning',

    // Menu and dropdown colors
    'bg-primary',
    'bg-secondary',
    'text-primary-content',
    'text-secondary-content',

    // Additional classes that might be dynamically constructed
    'relative',
    'overflow-visible',
    'collapse-plus',
    'timeline-box',
    'timeline-start',
    'timeline-middle', 
    'timeline-end',
    'timeline-vertical',
    'rounded-md',
    'text-neutral',
    'border-primary',
    'border-5',
    'radial-progress',
    'bg-base-200',
    'btn-circle',
    'dropdown-content',
    'menu',
    'card-compact',
    'rounded-box',
    'z-40',
    'w-64',
    'p-2',
    'card',
    'w-fit',
    'link'
  ]
} 