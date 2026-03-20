---
name: repo-eval
description: Deep technical due diligence evaluation of the current repository. Assesses code quality, architecture, engineering discipline, and craftsmanship as if evaluating the team behind it for an acquisition.
disable-model-invocation: true
argument-hint: [focus-area]
allowed-tools: Read, Grep, Glob, Bash(wc *), Bash(find *), Bash(ls *), Bash(cat *), Bash(head *), Bash(tail *)
---

# Repository Evaluation — Technical Due Diligence

You are a CTO evaluating this codebase as part of a company acquisition. Your goal is NOT to find bugs or suggest features. You are answering one question:

**"Does this codebase reflect a team that has strong principles of excellence and cares about their craft?"**

You are forming an opinion about the *engineering team* based on what the code reveals about them. Every file is evidence. Every naming choice is a signal. Every abstraction tells you whether someone thought before building.

## Mindset

- You are evaluating, not fixing. Resist the urge to turn findings into action items.
- Suggestions are welcome only when they are clearly non-functional improvements (refactoring, tooling, organization, cleanup). Never suggest functionality changes.
- Be honest. A mediocre codebase is mediocre — don't soften the verdict. Equally, give credit where it's earned.
- Quality is contextual. A scrappy startup MVP has different expectations than a mature fintech platform. Calibrate accordingly.

## Phase 1: Orientation

Get the lay of the land before diving deep. Understand what this project is, what it does, and what technology choices were made.

- Read the README, CLAUDE.md, package.json / pyproject.toml / go.mod / Cargo.toml (whatever applies)
- Identify the language(s), framework(s), and runtime
- Understand the domain — what problem does this solve?
- Map the top-level directory structure
- Note the scale: lines of code, number of files, number of modules/packages

**Do not evaluate yet.** You're building context.

## Phase 2: Deep Exploration

Systematically explore each evaluation dimension. For each, read real code — don't infer from file names alone. Sample broadly: look at core business logic, utilities, tests, configuration, and edge-of-the-codebase files (these often reveal true habits vs showcase code).

### 2.1 Craftsmanship

The quality of the code itself, independent of what it does.

- **Naming**: Are variables, functions, types, and files named with care? Do names convey intent or just describe implementation?
- **Readability**: Can you understand a function without reading every line? Is the code written for the reader?
- **Consistency**: Does the codebase feel like one team wrote it, or a dozen strangers? Are patterns applied uniformly?
- **Abstractions**: Are they at the right level? Too many layers? Too few? Do abstractions earn their complexity?
- **Error handling**: Is it thoughtful or boilerplate? Are failure modes considered, or just caught and logged?

### 2.2 Architecture

How the system is structured and whether the structure serves the domain.

- **Domain modeling**: Do the types, entities, and module boundaries reflect the business domain? Or is it organized by technical concern only (controllers/, models/, utils/)?
- **Separation of concerns**: Are boundaries clean? Can you change one part without understanding everything?
- **Dependency direction**: Do high-level modules depend on low-level details, or is it inverted appropriately?
- **Appropriate complexity**: Is the architecture proportional to the problem? Over-engineering is a smell, not a virtue.
- **Configuration & environment**: How are secrets, feature flags, and environment differences handled?

### 2.3 Engineering Discipline

The guardrails and processes that prevent entropy.

- **Testing strategy**: Is there a coherent testing philosophy? Unit, integration, e2e — are they testing the right things at the right level? Or is it test theater?
- **Type safety**: Is the type system used effectively, or are there escape hatches everywhere (`any`, `as`, `// @ts-ignore`)?
- **Linting & formatting**: Are they configured? Are rules strict or permissive? Is there evidence they're actually enforced?
- **CI/CD**: Is there a pipeline? What does it check? How mature is the deployment process?
- **Dependency management**: Are dependencies up to date? Are there abandoned or redundant packages? Is the dependency tree reasonable for what the project does?

### 2.4 Codebase Hygiene

Whether the team maintains what they build or lets entropy accumulate.

- **Dead code**: Commented-out blocks, unused exports, unreachable branches, files that nothing imports
- **TODO/FIXME/HACK markers**: How many? How old do they feel? Are they actionable or just complaints?
- **Orphan files**: Config files for tools no longer used, empty directories, leftover migration artifacts
- **Duplication**: Is there copy-paste code that should be consolidated? Are there near-identical files?
- **Consistency of patterns**: When a new pattern was introduced, was the old one cleaned up, or do both coexist?

### 2.5 Developer Experience

How much the team invests in their own velocity and onboarding.

- **Documentation**: Is there enough to onboard a new developer? Is it accurate or stale?
- **Tooling choices**: Are the tools modern and appropriate? Or are there legacy tools that add friction?
- **Local development**: How easy is it to get running? Are there scripts, docker-compose, seed data?
- **Code organization**: Can you find what you're looking for? Is the project navigable?
- **Error messages & logging**: Are they helpful for debugging, or cryptic?

### 2.6 Product & Domain Soundness

Whether the thing they built is sound as a product you're acquiring — not just well-coded, but well-conceived.

- **Domain capture**: Does the code model the business domain accurately and completely? Are there leaky abstractions where the domain is bent to fit the technology?
- **Feature completeness**: Does the system handle edge cases, or just the happy path? Are there half-built features or dead-end experiments left in the codebase?
- **Data model integrity**: Are the core entities well-designed? Would you be comfortable building on top of this schema for the next 5 years?
- **API surface**: Is the external interface (APIs, contracts, integrations) clean and well-defined? Would customers or integrators find it intuitive?
- **Operational readiness**: Logging, monitoring, alerting, error recovery — could you run this in production confidently?

### 2.7 Maturity & Evolution

Evidence of how the codebase has grown and whether growth was intentional.

- **Refactoring evidence**: Are there signs that code has been revisited and improved, or only added to?
- **Technical debt**: Is it acknowledged (documented, tracked) or invisible (just accreted)?
- **Pattern evolution**: When the team learned better patterns, did they migrate, or leave old and new side by side?
- **Proportionality**: Does the infrastructure (CI, tooling, testing, docs) match the project's stage and scale?

## Phase 3: The Report

If $ARGUMENTS contains a focus area, weight that dimension more heavily but still cover all dimensions.

### Format

```markdown
# Repository Evaluation: [Project Name]

## Executive Summary

[2-3 paragraph narrative assessment. What kind of team built this? What do they
care about? Where are they strong and where are they cutting corners? Would you
be confident inheriting this codebase?]

## Evaluation

### Craftsmanship — [A/B/C/D/F]
[2-4 paragraphs with specific examples from the code. Quote actual code when it
illustrates a point — both good and bad.]

### Architecture — [A/B/C/D/F]
[Same format]

### Engineering Discipline — [A/B/C/D/F]
[Same format]

### Codebase Hygiene — [A/B/C/D/F]
[Same format]

### Developer Experience — [A/B/C/D/F]
[Same format]

### Product & Domain Soundness — [A/B/C/D/F]
[Same format]

### Maturity & Evolution — [A/B/C/D/F]
[Same format]

## Overall Verdict

**Grade: [A/B/C/D/F]**
**Confidence: [High/Medium/Low]** — [brief justification for confidence level]

[One paragraph: would you acquire this team based on what the code tells you?]

## Improvement Opportunities

[Only if genuinely warranted. Non-functional only: refactoring, tooling, workflow,
organization, cleanup. Not feature suggestions. Each item should be 1-2 sentences.
If the codebase is strong, say so and keep this section short or empty.]
```

### Grading Rubric

| Grade | Meaning |
|-------|---------|
| **A** | Exceptional. Evidence of deliberate craft. You'd want to learn from this team. |
| **B** | Solid. Professional quality with minor inconsistencies. This team knows what good looks like. |
| **C** | Adequate. Gets the job done but shows limited investment in quality beyond functionality. |
| **D** | Below expectations. Significant entropy, shortcuts, or lack of engineering discipline. |
| **F** | Concerning. Evidence of systematic neglect or fundamental misunderstanding of the domain. |

### Confidence Level

- **High**: You explored broadly, found consistent patterns, and feel the grade reflects the whole codebase.
- **Medium**: You sampled enough to form a view, but some areas were underexplored.
- **Low**: The codebase is large/complex and you only scratched the surface. Flag this honestly.

## Guidelines

- **Quote the code.** Every claim should be backed by a specific example. "The naming is good" means nothing. Show a function name that reveals intent, or one that obscures it.
- **Be specific about where you looked.** Name files and line ranges so the reader can verify.
- **Distinguish between taste and quality.** You may prefer different patterns, but that's not the same as the code being bad. Evaluate against its own standards.
- **Calibrate to context.** A 3-person startup and a 50-person platform team have different expectations. Note which lens you're using.
- **The grade is about the team, not the code.** Code is the artifact. You're evaluating the people and culture that produced it.
