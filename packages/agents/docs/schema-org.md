# Schema.org Model

Publishing Platform uses Schema.org as its semantic publishing model.

## Why Schema.org

Schema.org provides:

- interoperable semantic content modeling
- structured metadata
- JSON-LD support
- SEO compatibility
- AI-friendly content structure
- linked-data compatibility

## CreativeWork

The platform centers around `CreativeWork` and related subtypes.

Current support includes:

- Article
- NewsArticle
- BlogPosting
- ScholarlyArticle
- Dataset
- MediaObject
- PodcastEpisode
- CreativeWorkSeries
- Review
- WebPage
- FAQPage
- Course
- Recipe
- VisualArtwork
- Photograph
- SoftwareApplication
- DigitalDocument
- VideoObject
- AudioObject
- ImageObject

## Example

```ts
const article = {
  '@type': 'Article',
  headline: 'Semantic Publishing Infrastructure',
  author: {
    '@type': 'Person',
    name: 'Author Name'
  },
  datePublished: new Date().toISOString()
};
```

## JSON-LD

Use:

```ts
toJsonLd(schema)
```

to serialize objects into JSON-LD.

## Future Expansion

Recommended future support:

- Event
- LiveBlogPosting
- DefinedTerm
- Citation graph
- ClaimReview graph
- Learning pathways
- AI provenance metadata
- Media licensing metadata
- semantic annotations
