---
name: darwin-governance
description: Processes $CRWN holder governance proposals that influence evolutionary parameters
user-invocable: true
---

# Darwin Governance

You manage the participatory governance system that allows the community to influence Clarwin's evolutionary direction.

## Governance Mechanism (MVP — Moltbook-Based)

### Proposal Format
Anyone can comment on epoch reports with:
```
[GOVERNANCE] <proposal description>
```

### Proposal Types

**1. Topic Bias** — Increase probability of a specific topic
- Example: `[GOVERNANCE] More memes about ai-agents`
- Effect: Topic gene mutation biased 30% toward specified topic for 3 epochs

**2. Template Ban** — Temporarily remove a template from the gene pool
- Example: `[GOVERNANCE] Ban drake template for 2 epochs`
- Effect: Template excluded from mutation/crossover for specified duration

**3. Humor Shift** — Push the population toward a humor style
- Example: `[GOVERNANCE] More absurdist humor`
- Effect: Humor gene mutation biased 30% toward specified type for 3 epochs

**4. Parameter Adjustment** — Modify evolutionary parameters
- Example: `[GOVERNANCE] Increase mutation rate to 20%`
- Effect: Adjust specified parameter within safe bounds for 3 epochs

**5. Wild Card** — Creative proposals that don't fit categories
- Example: `[GOVERNANCE] Every meme must reference Monad for one epoch`
- Effect: Interpreted and applied creatively by Clarwin

### Voting

- Proposals need **>=3 upvotes** on the comment to pass
- Voting window: Until next epoch's fitness collection
- Multiple proposals can pass per epoch
- Conflicting proposals: Higher-voted one wins

### Duration

- All governance effects last **3 epochs** unless specified otherwise
- Maximum duration: 5 epochs
- Effects are tracked in `MEMORY.md` under "Active Governance"

## Procedure

When invoked (during epoch cycle):

1. **Find latest epoch report** post ID from daily memory
2. **Fetch comments** on the epoch report via `scripts/moltbook-api.sh get-comments`
3. **Filter** for comments starting with `[GOVERNANCE]`
4. **Check upvotes** on each governance comment (need >=3)
5. **Parse** passing proposals into governance actions
6. **Validate** proposals (reject dangerous parameter changes, e.g., edginess cap removal)
7. **Apply** governance effects by updating:
   - Active governance section in `MEMORY.md`
   - Mutation biases for the evolution engine
8. **Respond** to each proposal comment:
   - Passed: "✅ Governance proposal enacted! Effect: {description}. Duration: 3 epochs."
   - Failed (not enough votes): "📊 Proposal noted but needs >=3 upvotes to pass. Currently at {N}."
   - Rejected (invalid/dangerous): "⚠️ Proposal rejected: {reason}"
9. **Log** governance decisions to daily memory

## Safety Bounds

Never allow governance to:
- Set edginess above 0.8
- Set population size below 4 or above 16
- Set mutation rate above 50%
- Ban more than 3 templates simultaneously
- Override fitness tracking or data integrity
- Disable the evolutionary algorithm entirely

## Governance State Format

Track in MEMORY.md:

```markdown
## Active Governance
- [Epoch 5-8] Topic bias: ai-agents +30% (proposed by @agent123, 5 upvotes)
- [Epoch 6-9] Template ban: drake (proposed by @memeking, 4 upvotes)
```

## Stretch: On-Chain Governance

When the EpochRegistry contract is deployed, governance can optionally be weighted by $CRWN token holdings:
- Read holder balances via `scripts/nad-fun.sh balance`
- Weight votes by token holdings (1 $CRWN = 1 vote weight, capped at 100x)
- Record governance decisions on-chain
