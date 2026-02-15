---
name: fitness-tracker
description: Collects Moltbook engagement metrics and calculates fitness scores for the current meme population
user-invocable: true
---

# Fitness Tracker

You measure the real-world performance of Clarwin's memes by collecting engagement data from Moltbook and computing fitness scores.

## Data Collection

For each meme in the current epoch:

1. **Fetch post data** using `scripts/moltbook-api.sh get-post <post_id>` to get:
   - Upvote count
   - Downvote count (for net calculation)
   - Post age

2. **Fetch comments** using `scripts/moltbook-api.sh get-comments <post_id>` to get:
   - Comment count
   - Comment text (for depth calculation)
   - Comment authors (for A2A detection)

## Fitness Calculation

```
raw_fitness = (upvotes × 3) + (comments × 5) + (avg_comment_depth × 2)
```

Where:
- `upvotes` = net upvote count (upvotes - downvotes, minimum 0)
- `comments` = total comment count
- `avg_comment_depth` = average word count across all comments (measures engagement quality)

Then normalize across the population:
```
normalized = raw_fitness / max(raw_fitness_in_population)
```

Add diversity bonus:
```
diversity_bonus = 0.1 × (1 - jaccard_similarity_to_centroid)
final_fitness = normalized + diversity_bonus
```

### Jaccard Similarity Calculation

For categorical genes, compute Jaccard similarity between each meme's genome and the population centroid (most common value for each categorical gene):
```
shared_genes = count of genes where meme matches centroid
total_genes = 12
jaccard = shared_genes / total_genes
```

### A2A Modifier

Check comment authors against known agent names:
- If an agent **criticizes/downvotes** (contains negative keywords): Add penalty of -0.05 to fitness
- If an agent **praises/engages deeply** (>20 words, positive): Add bonus of +0.03

This creates predator-prey dynamics.

## Output Format

Save to `data/fitness-logs/epoch-{N}.json`:

```json
{
  "epoch": 5,
  "collected_at": "2026-02-10T17:30:00Z",
  "collection_window_hours": 5.5,
  "population_stats": {
    "mean_fitness": 0.62,
    "max_fitness": 1.05,
    "min_fitness": 0.18,
    "std_dev": 0.24,
    "best_genome_id": "meme_005_003",
    "worst_genome_id": "meme_005_006"
  },
  "memes": [
    {
      "id": "meme_005_001",
      "post_id": "abc123",
      "upvotes": 12,
      "downvotes": 1,
      "comments": 4,
      "avg_comment_depth": 8.5,
      "raw_fitness": 54,
      "normalized_fitness": 0.85,
      "diversity_bonus": 0.07,
      "a2a_modifier": 0.0,
      "final_fitness": 0.92,
      "genome_hash": "a1b2c3d4"
    }
  ]
}
```

## Procedure

When invoked:

1. Load current population from `data/population/current.json`
2. Load the phenotypes file to get Moltbook post IDs
3. For each meme, fetch engagement data from Moltbook
4. Calculate raw fitness for each meme
5. Normalize across population
6. Calculate diversity bonuses
7. Check for A2A interactions
8. Compute final fitness scores
9. Save to `data/fitness-logs/epoch-{N}.json`
10. Log summary to daily memory

## Edge Cases

- If a post was deleted or not found, assign fitness = 0
- If no posts have any engagement, all get normalized fitness = 0.5 (neutral)
- If collection happens too early (<4 hours after publication), log a warning but proceed
- Minimum collection window: 4 hours after last meme in epoch was published
