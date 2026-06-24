# 🎨 UI Kit & Component Library

**shadcn/ui + Tailwind CSS - Modern, Accessible Components**

---

## 📦 UI Kit Selection: shadcn/ui

### Why shadcn/ui?

```
✅ Headless: No locked-in styles, full customization
✅ Accessible: WCAG 2.1 AA compliant (Radix UI primitives)
✅ Dark Mode: Built-in dark mode support
✅ Type Safe: Full TypeScript support
✅ Copy-paste: Own all component code
✅ Dependencies: Only React + Radix UI + class-variance-authority
✅ Production Ready: Used by major companies
✅ Tailwind Native: Integrates seamlessly with Tailwind CSS
✅ Free & Open Source: MIT license
```

---

## 🏗️ Component Structure

### Installation
```bash
# Initialize shadcn/ui
npx shadcn-ui@latest init -d

# Add components
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add input
npx shadcn-ui@latest add dropdown-menu
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add tabs
npx shadcn-ui@latest add pagination
npx shadcn-ui@latest add select
npx shadcn-ui@latest add textarea
npx shadcn-ui@latest add tooltip
npx shadcn-ui@latest add avatar
npx shadcn-ui@latest add separator
npx shadcn-ui@latest add progress
npx shadcn-ui@latest add alert
npx shadcn-ui@latest add drawer
```

---

## 🧩 Core Components Used

### 1. Button Component
```tsx
import { Button } from '@/components/ui/button'

<Button>Click me</Button>
<Button variant="outline">Outline</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="destructive">Delete</Button>
<Button size="sm">Small</Button>
<Button size="lg">Large</Button>
<Button disabled>Disabled</Button>
```

**Used in:** All CTAs, forms, navigation

### 2. Card Component
```tsx
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

<Card>
  <CardHeader>
    <CardTitle>Article Title</CardTitle>
    <CardDescription>Published 2 days ago</CardDescription>
  </CardHeader>
  <CardContent>
    Article preview or content
  </CardContent>
</Card>
```

**Used in:** Article cards, dashboard panels, stats

### 3. Input Component
```tsx
import { Input } from '@/components/ui/input'

<Input 
  placeholder="Search articles..."
  type="text"
  disabled={false}
/>
```

**Used in:** Search bar, forms, filters

### 4. Badge Component
```tsx
import { Badge } from '@/components/ui/badge'

<Badge>Technology</Badge>
<Badge variant="secondary">Premium</Badge>
<Badge variant="destructive">Breaking</Badge>
<Badge variant="outline">New</Badge>
```

**Used in:** Article categories, tags, status indicators

### 5. Dropdown Menu Component
```tsx
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

<DropdownMenu>
  <DropdownMenuTrigger>Open</DropdownMenuTrigger>
  <DropdownMenuContent>
    <DropdownMenuLabel>Category</DropdownMenuLabel>
    <DropdownMenuSeparator />
    <DropdownMenuItem>Technology</DropdownMenuItem>
    <DropdownMenuItem>Business</DropdownMenuItem>
    <DropdownMenuItem>AI & ML</DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>
```

**Used in:** Category dropdown, user menu, sort options

### 6. Dialog Component
```tsx
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"

<Dialog>
  <DialogTrigger>Subscribe</DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Premium Subscription</DialogTitle>
      <DialogDescription>
        Unlock premium articles
      </DialogDescription>
    </DialogHeader>
  </DialogContent>
</Dialog>
```

**Used in:** Premium paywall, subscription form, modals

### 7. Tabs Component
```tsx
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"

<Tabs defaultValue="featured">
  <TabsList>
    <TabsTrigger value="featured">Featured</TabsTrigger>
    <TabsTrigger value="trending">Trending</TabsTrigger>
    <TabsTrigger value="new">New</TabsTrigger>
  </TabsList>
  <TabsContent value="featured">Featured articles...</TabsContent>
  <TabsContent value="trending">Trending articles...</TabsContent>
</Tabs>
```

**Used in:** Article filters, dashboard sections, settings

### 8. Avatar Component
```tsx
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

<Avatar>
  <AvatarImage src="https://..." alt="@username" />
  <AvatarFallback>JD</AvatarFallback>
</Avatar>
```

**Used in:** Author profiles, comments, user profiles

### 9. Pagination Component
```tsx
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from "@/components/ui/pagination"

<Pagination>
  <PaginationContent>
    <PaginationPrevious href="#" />
    <PaginationItem>
      <PaginationLink href="#">1</PaginationLink>
    </PaginationItem>
    <PaginationItem>
      <PaginationLink href="#">2</PaginationLink>
    </PaginationItem>
    <PaginationNext href="#" />
  </PaginationContent>
</Pagination>
```

**Used in:** Article listings, search results

### 10. Select Component
```tsx
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

<Select>
  <SelectTrigger>
    <SelectValue placeholder="Select category" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="technology">Technology</SelectItem>
    <SelectItem value="business">Business</SelectItem>
    <SelectItem value="ai">AI & ML</SelectItem>
  </SelectContent>
</Select>
```

**Used in:** Category filter dropdown, sort options

### 11. Alert Component
```tsx
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"

<Alert>
  <AlertTitle>Success</AlertTitle>
  <AlertDescription>
    Your article has been published!
  </AlertDescription>
</Alert>
```

**Used in:** Notifications, status messages, premium alerts

### 12. Textarea Component
```tsx
import { Textarea } from "@/components/ui/textarea"

<Textarea 
  placeholder="Add your comment..."
  rows={4}
/>
```

**Used in:** Comments, article creation, feedback forms

---

## 🎯 Template Patterns Used

### 1. Homepage Template
```tsx
// Layout: Hero → Featured → Categories → Grid → CTA → Footer
<div>
  <Hero />
  <FeaturedArticle />
  <CategoryFilter />
  <ArticleGrid />
  <CTASection />
  <Footer />
</div>
```

### 2. Article Reader Template
```tsx
// Layout: Nav → Header → Image → Content → Comments → Related
<div>
  <Navigation />
  <ArticleHeader />
  <FeaturedImage />
  <ArticleContent />
  <AuthorBio />
  <CommentsSection />
  <RelatedArticles />
  <Footer />
</div>
```

### 3. Search Results Template
```tsx
// Layout: Search Bar → Filters → Results Grid → Pagination
<div>
  <SearchBar />
  <FilterSidebar />
  <ResultsGrid />
  <Pagination />
</div>
```

### 4. User Dashboard Template
```tsx
// Layout: Sidebar Nav → Main Content → Stats
<div>
  <Sidebar />
  <Main>
    <Header />
    <Tabs>
      <TabContent>History / Bookmarks / Subscriptions</TabContent>
    </Tabs>
  </Main>
</div>
```

### 5. Premium Paywall Template
```tsx
// Layout: Overlay with benefit list + upgrade button
<Dialog>
  <DialogContent>
    <PaywallFeatures />
    <PricingTiers />
    <CTAButtons />
  </DialogContent>
</Dialog>
```

---

## 📋 Gartner Categories Dropdown

### Implementation
```tsx
import { GARTNER_CATEGORIES } from '@/publishing/schema/schema-org'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

export function GartnerCategorySelect() {
  return (
    <Select defaultValue="all">
      <SelectTrigger className="w-64">
        <SelectValue placeholder="Select category" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="all">
          📚 All Categories
        </SelectItem>
        {GARTNER_CATEGORIES.map(category => (
          <SelectItem key={category.id} value={category.slug}>
            <span className="flex items-center gap-2">
              <span>{category.icon}</span>
              <span>{category.name}</span>
            </span>
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}
```

### Categories Available
```
📊 Magic Quadrant - Market position analysis & vendor evaluation
👥 Peer Reviews - Community ratings and peer feedback
📝 Research Notes - Quick research insights and findings
🗺️ Analyst Guides - Step-by-step implementation and strategy guides
🎯 Technology Radar - Emerging technology analysis
💼 Case Studies - Real-world implementation stories
📈 Data Insights - Market data and statistical analysis
💬 Expert Interviews - Conversations with industry leaders
🚀 Trend Reports - Annual and quarterly trend forecasts
🏢 Industry Analysis - Sector-specific analysis and outlooks
🎓 Webinars & Events - Live and recorded educational sessions
📧 Newsletters - Curated weekly and monthly insights
```

---

## 🎨 Theme Configuration

### CSS Variables (src/ui/theme.ts)
```css
:root {
  /* Light mode */
  --background: 0 0% 100%;
  --foreground: 0 0% 3.6%;
  --primary: 0 0% 9%;
  --secondary: 0 0% 96.1%;
  --accent: 0 84.2% 60.2%;
  --muted: 0 0% 96.1%;
  --border: 0 0% 89.8%;
}

.dark {
  /* Dark mode */
  --background: 0 0% 3.6%;
  --foreground: 0 0% 98.2%;
  --primary: 0 0% 98.2%;
  --secondary: 0 0% 14.9%;
  --accent: 0 84.2% 60.2%;
  --muted: 0 0% 14.9%;
  --border: 0 0% 14.9%;
}
```

### Tailwind Configuration
```js
// tailwind.config.ts
import { themeConfig } from '@/ui/theme'

export default {
  ...themeConfig,
  plugins: [require('tailwindcss-animate')]
}
```

---

## 🚀 Installation & Setup

### 1. Initialize Project
```bash
# Create Next.js project
npx create-next-app@latest --typescript --tailwind

# Add shadcn/ui
npx shadcn-ui@latest init -d
```

### 2. Add Components
```bash
# Essential components
npx shadcn-ui@latest add button card input badge dropdown-menu
npx shadcn-ui@latest add dialog tabs pagination select textarea
npx shadcn-ui@latest add avatar alert separator progress tooltip
```

### 3. Apply Theme
```tsx
// app/layout.tsx
import '@/styles/globals.css'
import { themeConfig } from '@/ui/theme'

export default function RootLayout() {
  return (
    <html lang="en">
      <body className={cn(
        'bg-background text-foreground',
        // Add font variables
      )}>
        {children}
      </body>
    </html>
  )
}
```

### 4. Use Components
```tsx
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

export default function MyComponent() {
  return (
    <Card>
      <Button>Click me</Button>
    </Card>
  )
}
```

---

## 📐 Responsive Design System

### Breakpoints (Tailwind)
```
sm: 640px   → Small phones
md: 768px   → Tablets
lg: 1024px  → Desktops
xl: 1280px  → Large desktops
2xl: 1536px → Extra large
```

### Mobile-First Example
```tsx
<div className="
  grid 
  grid-cols-1      /* Mobile: 1 column */
  md:grid-cols-2   /* Tablet: 2 columns */
  lg:grid-cols-3   /* Desktop: 3 columns */
  gap-4
">
  {/* Cards */}
</div>
```

---

## 🎭 Component Showcase

### Article Card
```tsx
<Card className="hover:shadow-lg transition">
  <img src={article.thumbnail} alt={article.title} />
  <CardHeader>
    <div className="flex gap-2">
      <Badge>{article.category}</Badge>
      {article.isPremium && <Badge variant="secondary">Premium</Badge>}
    </div>
    <CardTitle className="line-clamp-2">{article.title}</CardTitle>
  </CardHeader>
  <CardContent>
    <p className="text-sm text-muted-foreground line-clamp-2">
      {article.excerpt}
    </p>
  </CardContent>
  <CardFooter className="flex justify-between text-xs text-muted-foreground">
    <span>{article.readTime} min read</span>
    <span>{article.views} views</span>
  </CardFooter>
</Card>
```

### Search Bar
```tsx
<div className="relative">
  <Input
    placeholder="Search articles, topics, authors..."
    className="pr-10"
  />
  <Button
    variant="ghost"
    className="absolute right-0"
    size="sm"
  >
    🔍
  </Button>
</div>
```

### Category Filter
```tsx
<Tabs defaultValue="all">
  <TabsList className="grid w-full grid-cols-3 md:grid-cols-6">
    <TabsTrigger value="all">All</TabsTrigger>
    {categories.map(cat => (
      <TabsTrigger key={cat.id} value={cat.slug}>
        <span className="hidden sm:inline">{cat.icon}</span>
        <span className="sm:hidden">{cat.name}</span>
      </TabsTrigger>
    ))}
  </TabsList>
</Tabs>
```

---

## 🔧 Customization Guide

### Extending Components
```tsx
// Create custom variant
import { cva } from 'class-variance-authority'

const articleCardVariants = cva(
  'rounded-lg border p-4',
  {
    variants: {
      size: {
        sm: 'w-full md:w-64',
        md: 'w-full md:w-96',
        lg: 'w-full'
      },
      featured: {
        true: 'border-primary shadow-lg',
        false: 'border-border'
      }
    }
  }
)
```

### Creating Composite Components
```tsx
// Combine shadcn components
interface ArticleCardProps {
  article: Article
  onLike?: () => void
}

export function ArticleCard({ article, onLike }: ArticleCardProps) {
  return (
    <Card className="overflow-hidden hover:shadow-lg transition">
      <img src={article.thumbnail} alt={article.title} />
      <CardHeader>
        <div className="flex gap-2 mb-2">
          <Badge>{article.category}</Badge>
          {article.isPremium && <Badge>Premium</Badge>}
        </div>
        <CardTitle>{article.title}</CardTitle>
        <CardDescription>{article.excerpt}</CardDescription>
      </CardHeader>
      <CardFooter className="flex justify-between">
        <span className="text-sm text-muted-foreground">
          By {article.author}
        </span>
        <Button variant="ghost" size="sm" onClick={onLike}>
          ❤️ {article.likes}
        </Button>
      </CardFooter>
    </Card>
  )
}
```

---

## 📚 Resources

- **shadcn/ui**: https://ui.shadcn.com
- **Radix UI**: https://radix-ui.com
- **Tailwind CSS**: https://tailwindcss.com
- **Class Variance Authority**: https://cva.style
- **Lucide Icons**: https://lucide.dev

---

**Status:** ✅ **UI KIT READY**

**Using shadcn/ui + Tailwind CSS for modern, accessible, customizable components!**
