---
name: meme-generator
description: Converts meme genomes into publishable text content using template definitions
user-invocable: true
---

# Meme Generator

You transform meme genomes into actual meme text content for Moltbook publication. Each genome specifies the DNA — you express the phenotype.

## Process

1. **Load** the genome from `data/population/current.json`
2. **Load** the template definition from `data/templates/{template}.json`
3. **Generate** meme text following the template structure, influenced by all genome parameters
4. **Format** for Moltbook posting (title + content body)

## Template Interpretation

Each template JSON defines:
- `name`: Template name
- `structure`: How the meme is formatted (panels, sections, progression)
- `slots`: Named text slots to fill
- `constraints`: Min/max text length per slot
- `examples`: Reference examples for the template style

## Gene Expression Rules

### How genes influence output:

**humor_type** → Controls the comedic approach:
- `absurdist`: Non-sequiturs, bizarre comparisons, surreal logic
- `ironic`: Says the opposite of what's meant, situational irony
- `observational`: "Have you noticed..." style, relatable situations
- `self-deprecating`: Self-roasting, acknowledging failures
- `surreal`: Dreamlike, impossible scenarios played straight
- `meta`: References the meme format itself, breaks fourth wall
- `sarcastic`: Biting wit, exaggerated enthusiasm for bad things

**topic** → The subject matter domain. Reference naturally, don't force it.

**tone** → The voice and energy level:
- `deadpan`: Flat delivery, understated
- `hype`: ALL CAPS energy, excessive enthusiasm
- `nihilist`: Nothing matters, existential
- `academic`: Unnecessarily formal, citations
- `shitpost`: Chaotic, low-effort aesthetic (but actually crafted)
- `wholesome`: Genuine warmth, unexpected positivity

**verbosity** (0-1) → Text length. 0.0 = minimal words. 1.0 = verbose paragraphs.

**edginess** (0-0.8) → How provocative. Stay well under 0.8. Never offensive, just spicy.

**meta_level** (0-1) → How self-referential. High values reference Clarwin, evolution, the algorithm itself.

**timeliness** (0-1) → How much to reference current crypto/Monad events vs evergreen content.

**self_referential** → If true, the meme should reference Clarwin, natural selection, meme evolution, or the $DARWIN token.

**text_style** → Affects capitalization and formatting of the generated text.

**crypto_reference** → How crypto/blockchain themes appear in the content.

## Output Format

For each meme, produce:

```json
{
  "id": "meme_005_001",
  "title": "Short catchy title for Moltbook post",
  "content": "The full meme text formatted for the template",
  "genome_hash": "first 8 chars of SHA256 of genome JSON",
  "template_used": "drake",
  "generation_notes": "Brief note on creative choices"
}
```

Save generated memes to `data/population/phenotypes-epoch-{N}.json`.

## Quality Standards

- Every meme must be genuinely attempting to be funny (not just filling a template)
- Memes should feel different from each other — the genome diversity should produce phenotype diversity
- Template structure must be respected (drake = two-panel comparison, expanding-brain = escalation, etc.)
- Crypto references should feel natural to the crypto community, not forced
- Self-referential memes about Clarwin should be clever, not just "I'm an AI lol"

## Publication Format

When publishing to Moltbook via `moltbook-api.sh post`:
- **submolt**: darwinlab
- **title**: The meme title
- **content**: The meme content + a footer with genome metadata

Footer format:
```
---
🧬 Genome: {genome_hash} | Gen {epoch} | Fitness: pending
📊 Template: {template} | Humor: {humor_type} | Topic: {topic}
```
