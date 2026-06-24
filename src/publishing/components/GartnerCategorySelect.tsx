// src/publishing/components/GartnerCategorySelect.tsx
'use client'

import React from 'react'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  SelectGroup,
  SelectLabel,
  SelectSeparator
} from '@/components/ui/select'
import { GARTNER_CATEGORIES } from '@/publishing/schema/schema-org'
import { Badge } from '@/components/ui/badge'

interface GartnerCategorySelectProps {
  value?: string
  onChange?: (value: string) => void
  placeholder?: string
  showAllOption?: boolean
}

export function GartnerCategorySelect({
  value,
  onChange,
  placeholder = 'Select category...',
  showAllOption = true
}: GartnerCategorySelectProps) {
  return (
    <Select value={value} onValueChange={onChange}>
      <SelectTrigger className="w-full md:w-72 bg-white dark:bg-slate-900">
        <SelectValue placeholder={placeholder} />
      </SelectTrigger>
      <SelectContent className="w-72">
        {showAllOption && (
          <>
            <SelectItem value="all" className="cursor-pointer">
              <div className="flex items-center gap-2">
                <span className="text-lg">📚</span>
                <span className="font-medium">All Categories</span>
              </div>
            </SelectItem>
            <SelectSeparator />
          </>
        )}

        {/* Analyst Research Section */}
        <SelectGroup>
          <SelectLabel className="text-xs font-bold text-gray-600 dark:text-gray-400">
            ANALYST RESEARCH
          </SelectLabel>

          {GARTNER_CATEGORIES.slice(0, 3).map((category) => (
            <SelectItem
              key={category.id}
              value={category.slug}
              className="cursor-pointer py-2"
            >
              <div className="flex items-center gap-2">
                <span className="text-lg">{category.icon}</span>
                <div className="flex flex-col">
                  <span className="font-medium">{category.name}</span>
                  <span className="text-xs text-gray-500">
                    {category.description}
                  </span>
                </div>
              </div>
            </SelectItem>
          ))}
        </SelectGroup>

        <SelectSeparator />

        {/* Implementation & Guides Section */}
        <SelectGroup>
          <SelectLabel className="text-xs font-bold text-gray-600 dark:text-gray-400">
            IMPLEMENTATION & GUIDES
          </SelectLabel>

          {GARTNER_CATEGORIES.slice(3, 6).map((category) => (
            <SelectItem
              key={category.id}
              value={category.slug}
              className="cursor-pointer py-2"
            >
              <div className="flex items-center gap-2">
                <span className="text-lg">{category.icon}</span>
                <div className="flex flex-col">
                  <span className="font-medium">{category.name}</span>
                  <span className="text-xs text-gray-500">
                    {category.description}
                  </span>
                </div>
              </div>
            </SelectItem>
          ))}
        </SelectGroup>

        <SelectSeparator />

        {/* Insights & Analysis Section */}
        <SelectGroup>
          <SelectLabel className="text-xs font-bold text-gray-600 dark:text-gray-400">
            INSIGHTS & ANALYSIS
          </SelectLabel>

          {GARTNER_CATEGORIES.slice(6, 9).map((category) => (
            <SelectItem
              key={category.id}
              value={category.slug}
              className="cursor-pointer py-2"
            >
              <div className="flex items-center gap-2">
                <span className="text-lg">{category.icon}</span>
                <div className="flex flex-col">
                  <span className="font-medium">{category.name}</span>
                  <span className="text-xs text-gray-500">
                    {category.description}
                  </span>
                </div>
              </div>
            </SelectItem>
          ))}
        </SelectGroup>

        <SelectSeparator />

        {/* Community & Events Section */}
        <SelectGroup>
          <SelectLabel className="text-xs font-bold text-gray-600 dark:text-gray-400">
            COMMUNITY & EVENTS
          </SelectLabel>

          {GARTNER_CATEGORIES.slice(9).map((category) => (
            <SelectItem
              key={category.id}
              value={category.slug}
              className="cursor-pointer py-2"
            >
              <div className="flex items-center gap-2">
                <span className="text-lg">{category.icon}</span>
                <div className="flex flex-col">
                  <span className="font-medium">{category.name}</span>
                  <span className="text-xs text-gray-500">
                    {category.description}
                  </span>
                </div>
              </div>
            </SelectItem>
          ))}
        </SelectGroup>
      </SelectContent>
    </Select>
  )
}

// Simplified variant for category filter buttons
interface CategoryFilterProps {
  categories?: typeof GARTNER_CATEGORIES
  selected?: string
  onChange?: (slug: string) => void
  maxColumns?: number
}

export function CategoryFilter({
  categories = GARTNER_CATEGORIES,
  selected = 'all',
  onChange,
  maxColumns = 6
}: CategoryFilterProps) {
  return (
    <div className="space-y-3">
      <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">
        Browse by Category
      </h3>

      <div className={`grid gap-2 grid-cols-2 md:grid-cols-4 lg:grid-cols-${maxColumns}`}>
        {/* All Categories Button */}
        <button
          onClick={() => onChange?.('all')}
          className={`p-3 rounded-lg text-center font-medium transition ${
            selected === 'all'
              ? 'bg-blue-600 text-white ring-2 ring-blue-400'
              : 'bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 hover:bg-gray-200 dark:hover:bg-gray-700'
          }`}
        >
          <div className="text-lg mb-1">📚</div>
          <div className="text-xs font-medium">All Articles</div>
        </button>

        {/* Category Buttons */}
        {categories.map((category) => (
          <button
            key={category.id}
            onClick={() => onChange?.(category.slug)}
            className={`p-3 rounded-lg text-center font-medium transition ${
              selected === category.slug
                ? 'ring-2 ring-offset-2 ring-offset-white dark:ring-offset-gray-950'
                : 'hover:shadow-md'
            }`}
            style={{
              backgroundColor: selected === category.slug ? category.color : undefined,
              color: selected === category.slug ? 'white' : undefined
            }}
          >
            <div className="text-lg mb-1">{category.icon}</div>
            <div className="text-xs font-medium line-clamp-2">
              {category.name}
            </div>
            <div className="text-xs text-opacity-75 mt-1">
              {category.contentTypes.length} types
            </div>
          </button>
        ))}
      </div>
    </div>
  )
}

// Category badge component
interface CategoryBadgeProps {
  category: typeof GARTNER_CATEGORIES[0]
  className?: string
}

export function CategoryBadge({ category, className = '' }: CategoryBadgeProps) {
  return (
    <Badge
      className={`gap-1 ${className}`}
      style={{
        backgroundColor: category.color,
        color: 'white'
      }}
    >
      <span>{category.icon}</span>
      <span>{category.name}</span>
    </Badge>
  )
}

// Sidebar category list
export function CategorySidebar({
  categories = GARTNER_CATEGORIES,
  selected = 'all',
  onChange
}: CategoryFilterProps) {
  // Group categories by content type
  const groupedByType = categories.reduce((acc, cat) => {
    const type = cat.contentTypes[0] || 'other'
    if (!acc[type]) acc[type] = []
    acc[type].push(cat)
    return acc
  }, {} as Record<string, typeof GARTNER_CATEGORIES>)

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100 mb-3">
          Categories
        </h3>
        <button
          onClick={() => onChange?.('all')}
          className={`block w-full text-left px-3 py-2 rounded-lg transition ${
            selected === 'all'
              ? 'bg-blue-600 text-white font-medium'
              : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800'
          }`}
        >
          📚 All Categories
        </button>
      </div>

      {Object.entries(groupedByType).map(([type, cats]) => (
        <div key={type}>
          <h4 className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">
            {type}
          </h4>
          <div className="space-y-1">
            {cats.map((category) => (
              <button
                key={category.id}
                onClick={() => onChange?.(category.slug)}
                className={`block w-full text-left px-3 py-2 rounded-lg transition text-sm ${
                  selected === category.slug
                    ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 font-medium'
                    : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800'
                }`}
              >
                <span className="mr-2">{category.icon}</span>
                {category.name}
              </button>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}
