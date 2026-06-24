// src/publishing/schema/schema-org.ts
// Schema.org structured data for creative works and content types

export interface SchemaOrgCreativeWork {
  '@context': 'https://schema.org'
  '@type': string
  name: string
  description: string
  author: SchemaOrgPerson
  datePublished: string
  dateModified: string
  image?: string
  url: string
  wordCount?: number
  timeRequired?: string // ISO 8601 duration
}

export interface SchemaOrgPerson {
  '@type': 'Person'
  name: string
  url?: string
  image?: string
  jobTitle?: string
}

export interface SchemaOrgOrganization {
  '@type': 'Organization'
  name: string
  url: string
  logo?: string
  sameAs?: string[]
}

// Content Types based on Schema.org
export const SCHEMA_ORG_CONTENT_TYPES = {
  article: {
    type: 'Article',
    label: '📄 Article',
    description: 'News article or blog post',
    fields: ['headline', 'description', 'articleBody', 'datePublished', 'author']
  },
  researchArticle: {
    type: 'ScholarlyArticle',
    label: '🔬 Research Article',
    description: 'Academic or research paper',
    fields: ['headline', 'abstract', 'author', 'datePublished', 'keywords']
  },
  report: {
    type: 'Report',
    label: '📊 Report',
    description: 'Industry report or analysis',
    fields: ['name', 'description', 'datePublished', 'author', 'url']
  },
  whitepapers: {
    type: 'CreativeWork',
    label: '📋 Whitepaper',
    description: 'Technical whitepaper or detailed guide',
    fields: ['name', 'description', 'author', 'datePublished', 'pdf']
  },
  caseStudy: {
    type: 'CreativeWork',
    label: '💼 Case Study',
    description: 'Real-world implementation and results',
    fields: ['name', 'description', 'client', 'results', 'author']
  },
  infographic: {
    type: 'ImageObject',
    label: '📈 Infographic',
    description: 'Visual data representation',
    fields: ['name', 'image', 'description', 'datePublished']
  },
  video: {
    type: 'VideoObject',
    label: '🎥 Video',
    description: 'Video content',
    fields: ['name', 'description', 'url', 'uploadDate', 'duration']
  },
  podcast: {
    type: 'PodcastEpisode',
    label: '🎙️ Podcast',
    description: 'Audio/podcast episode',
    fields: ['name', 'description', 'url', 'uploadDate', 'duration']
  },
  webinar: {
    type: 'Event',
    label: '🎓 Webinar',
    description: 'Online educational event',
    fields: ['name', 'description', 'startDate', 'endDate', 'location']
  },
  guide: {
    type: 'HowTo',
    label: '🗺️ Guide',
    description: 'Step-by-step guide or tutorial',
    fields: ['name', 'description', 'step', 'image']
  },
  review: {
    type: 'Review',
    label: '⭐ Review',
    description: 'Product or service review',
    fields: ['name', 'description', 'reviewRating', 'author', 'datePublished']
  },
  comparison: {
    type: 'ComparisonChart',
    label: '⚖️ Comparison',
    description: 'Product/service comparison',
    fields: ['name', 'description', 'items', 'criteria']
  },
  peerReview: {
    type: 'Review',
    label: '👥 Peer Review',
    description: 'Gartner-style peer feedback and ratings',
    fields: ['name', 'description', 'rating', 'reviewCount', 'author', 'datePublished']
  },
  trendAnalysis: {
    type: 'CreativeWork',
    label: '📊 Trend Analysis',
    description: 'Market or technology trends',
    fields: ['name', 'description', 'datePublished', 'keywords', 'spatialCoverage']
  },
  interview: {
    type: 'Interview',
    label: '💬 Interview',
    description: 'Expert or personality interview',
    fields: ['name', 'description', 'interviewee', 'interviewer', 'datePublished']
  },
  newsletter: {
    type: 'CreativeWork',
    label: '📧 Newsletter',
    description: 'Email newsletter content',
    fields: ['name', 'description', 'datePublished', 'author']
  },
  eBook: {
    type: 'Book',
    label: '📚 eBook',
    description: 'Digital book or long-form guide',
    fields: ['name', 'description', 'author', 'datePublished', 'url']
  }
} as const

// Gartner-style Content Categories
export const GARTNER_CATEGORIES = [
  {
    id: '001-market-quadrant',
    name: 'Magic Quadrant',
    slug: 'magic-quadrant',
    icon: '📊',
    description: 'Market position analysis & vendor evaluation',
    color: '#FF6B6B',
    contentTypes: ['report', 'comparison']
  },
  {
    id: '002-peer-insights',
    name: 'Peer Reviews',
    slug: 'peer-reviews',
    icon: '👥',
    description: 'Community ratings and peer feedback',
    color: '#4ECDC4',
    contentTypes: ['peerReview', 'review']
  },
  {
    id: '003-research-notes',
    name: 'Research Notes',
    slug: 'research-notes',
    icon: '📝',
    description: 'Quick research insights and findings',
    color: '#45B7D1',
    contentTypes: ['article', 'researchArticle']
  },
  {
    id: '004-analyst-guides',
    name: 'Analyst Guides',
    slug: 'analyst-guides',
    icon: '🗺️',
    description: 'Step-by-step implementation and strategy guides',
    color: '#96CEB4',
    contentTypes: ['guide', 'whitepaper']
  },
  {
    id: '005-technology-radar',
    name: 'Technology Radar',
    slug: 'technology-radar',
    icon: '🎯',
    description: 'Emerging technology analysis',
    color: '#FFEAA7',
    contentTypes: ['trendAnalysis', 'article']
  },
  {
    id: '006-case-studies',
    name: 'Case Studies',
    slug: 'case-studies',
    icon: '💼',
    description: 'Real-world implementation stories',
    color: '#DDA0DD',
    contentTypes: ['caseStudy']
  },
  {
    id: '007-data-insights',
    name: 'Data Insights',
    slug: 'data-insights',
    icon: '📈',
    description: 'Market data and statistical analysis',
    color: '#87CEEB',
    contentTypes: ['infographic', 'report']
  },
  {
    id: '008-expert-interviews',
    name: 'Expert Interviews',
    slug: 'expert-interviews',
    icon: '💬',
    description: 'Conversations with industry leaders',
    color: '#FFB6C1',
    contentTypes: ['interview', 'video']
  },
  {
    id: '009-trend-reports',
    name: 'Trend Reports',
    slug: 'trend-reports',
    icon: '🚀',
    description: 'Annual and quarterly trend forecasts',
    color: '#FF8C00',
    contentTypes: ['report', 'trendAnalysis']
  },
  {
    id: '010-industry-analysis',
    name: 'Industry Analysis',
    slug: 'industry-analysis',
    icon: '🏢',
    description: 'Sector-specific analysis and outlooks',
    color: '#20B2AA',
    contentTypes: ['report', 'article']
  },
  {
    id: '011-webinars',
    name: 'Webinars & Events',
    slug: 'webinars',
    icon: '🎓',
    description: 'Live and recorded educational sessions',
    color: '#9370DB',
    contentTypes: ['webinar', 'video']
  },
  {
    id: '012-newsletters',
    name: 'Newsletters',
    slug: 'newsletters',
    icon: '📧',
    description: 'Curated weekly and monthly insights',
    color: '#FF69B4',
    contentTypes: ['newsletter', 'article']
  }
] as const

// Rich structured data for creative work
export function generateArticleSchema(article: any): SchemaOrgCreativeWork {
  return {
    '@context': 'https://schema.org',
    '@type': 'Article',
    name: article.title,
    description: article.excerpt,
    author: {
      '@type': 'Person',
      name: article.author,
      url: `/publishing/author/${article.author.toLowerCase().replace(/\s+/g, '-')}`,
      image: article.authorImage
    },
    datePublished: article.publishedAt,
    dateModified: article.updatedAt,
    image: article.thumbnail,
    url: `${process.env.NEXT_PUBLIC_SITE_URL}/publishing/article/${article.slug}`,
    wordCount: article.content.split(/\s+/).length,
    timeRequired: `PT${article.readTime}M`
  }
}

export function generateScholarlyArticleSchema(article: any): SchemaOrgCreativeWork {
  return {
    '@context': 'https://schema.org',
    '@type': 'ScholarlyArticle',
    name: article.title,
    description: article.excerpt,
    author: {
      '@type': 'Person',
      name: article.author,
      url: `/publishing/author/${article.author.toLowerCase().replace(/\s+/g, '-')}`,
      image: article.authorImage
    },
    datePublished: article.publishedAt,
    dateModified: article.updatedAt,
    image: article.thumbnail,
    url: `${process.env.NEXT_PUBLIC_SITE_URL}/publishing/article/${article.slug}`,
    wordCount: article.content.split(/\s+/).length
  }
}

export function generateReviewSchema(review: any) {
  return {
    '@context': 'https://schema.org',
    '@type': 'Review',
    name: review.title,
    description: review.description,
    reviewRating: {
      '@type': 'Rating',
      ratingValue: review.rating,
      bestRating: 5,
      worstRating: 1
    },
    author: {
      '@type': 'Person',
      name: review.author
    },
    datePublished: review.publishedAt,
    itemReviewed: {
      '@type': 'Thing',
      name: review.productName
    }
  }
}

export function generateComparisonSchema(comparison: any) {
  return {
    '@context': 'https://schema.org',
    '@type': 'ComparisonChart',
    name: comparison.title,
    description: comparison.description,
    url: `${process.env.NEXT_PUBLIC_SITE_URL}/publishing/comparison/${comparison.slug}`,
    datePublished: comparison.publishedAt,
    itemListElement: comparison.items.map((item: any, index: number) => ({
      '@type': 'Thing',
      position: index + 1,
      name: item.name,
      description: item.description
    }))
  }
}

export function generateBreadcrumbSchema(breadcrumbs: Array<{ name: string; url: string }>) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: breadcrumbs.map((crumb, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: crumb.name,
      item: `${process.env.NEXT_PUBLIC_SITE_URL}${crumb.url}`
    }))
  }
}

export function generateOrganizationSchema(): SchemaOrgOrganization {
  return {
    '@type': 'Organization',
    name: 'Creative Platform',
    url: process.env.NEXT_PUBLIC_SITE_URL || 'https://creative-platform.com',
    logo: `${process.env.NEXT_PUBLIC_SITE_URL}/logo.png`,
    sameAs: [
      'https://twitter.com/creativeplatform',
      'https://linkedin.com/company/creativeplatform'
    ]
  }
}
