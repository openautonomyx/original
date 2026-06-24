// src/ui/theme.ts
// shadcn/ui + Tailwind CSS Theme Configuration

import { type Config } from 'tailwindcss'

export const themeConfig = {
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))'
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))'
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))'
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))'
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))'
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))'
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))'
        }
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)'
      },
      fontFamily: {
        sans: ['var(--font-sans)', 'system-ui', 'sans-serif'],
        mono: ['var(--font-mono)', 'monospace']
      }
    }
  }
} as Config

// CSS Variables for theming
export const cssVariables = `
:root {
  --background: 0 0% 100%;
  --foreground: 0 0% 3.6%;
  --card: 0 0% 100%;
  --card-foreground: 0 0% 3.6%;
  --popover: 0 0% 100%;
  --popover-foreground: 0 0% 3.6%;
  --muted: 0 0% 96.1%;
  --muted-foreground: 0 0% 45.1%;
  --accent: 0 84.2% 60.2%;
  --accent-foreground: 0 0% 100%;
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 0 0% 100%;
  --border: 0 0% 89.8%;
  --input: 0 0% 89.8%;
  --primary: 0 0% 9%;
  --primary-foreground: 0 0% 100%;
  --secondary: 0 0% 96.1%;
  --secondary-foreground: 0 0% 9%;
  --ring: 0 0% 3.6%;
  --radius: 0.5rem;
}

.dark {
  --background: 0 0% 3.6%;
  --foreground: 0 0% 98.2%;
  --card: 0 0% 3.6%;
  --card-foreground: 0 0% 98.2%;
  --popover: 0 0% 3.6%;
  --popover-foreground: 0 0% 98.2%;
  --muted: 0 0% 14.9%;
  --muted-foreground: 0 0% 63.9%;
  --accent: 0 84.2% 60.2%;
  --accent-foreground: 0 0% 9%;
  --destructive: 0 80.6% 54.1%;
  --destructive-foreground: 0 0% 98.2%;
  --border: 0 0% 14.9%;
  --input: 0 0% 14.9%;
  --primary: 0 0% 98.2%;
  --primary-foreground: 0 0% 9%;
  --secondary: 0 0% 14.9%;
  --secondary-foreground: 0 0% 98.2%;
  --ring: 0 0% 83.3%;
}
`

// Component variants (shadcn/ui style)
export const buttonVariants = {
  default: 'bg-primary text-primary-foreground hover:bg-primary/90',
  destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
  outline: 'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
  secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
  ghost: 'hover:bg-accent hover:text-accent-foreground',
  link: 'text-primary underline-offset-4 hover:underline'
} as const

export const badgeVariants = {
  default: 'border-transparent bg-primary text-primary-foreground',
  secondary: 'border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80',
  destructive: 'border-transparent bg-destructive text-destructive-foreground',
  outline: 'text-foreground'
} as const

export const cardVariants = {
  default: 'rounded-lg border border-border bg-card text-card-foreground shadow-sm'
} as const

export const inputVariants = {
  default: 'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50'
} as const
