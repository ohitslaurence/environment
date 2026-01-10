---
description: Research AI tools, workflows, and dev productivity topics using Nia
argument-hint: [topic or question]
---

# AI Tools & Workflow Research

Research topic: $ARGUMENTS

## Instructions

Use Nia MCP server to perform comprehensive research. Execute these searches in parallel where possible:

### 1. Twitter/Social Search (quick)
```
mcp__nia__nia_research:
  query: "$ARGUMENTS tips tricks workflows"
  mode: quick
  category: tweet
  num_results: 10
```

### 2. GitHub Discovery (quick)
```
mcp__nia__nia_research:
  query: "$ARGUMENTS tools CLI automation"
  mode: quick
  category: github
  num_results: 10
```

### 3. General Web (quick)
```
mcp__nia__nia_research:
  query: "$ARGUMENTS best practices 2025"
  mode: quick
  num_results: 8
```

### 4. Deep Research
After quick searches complete, run deep research for comprehensive analysis:
```
mcp__nia__nia_research:
  query: "$ARGUMENTS"
  mode: deep
  output_format: "structured report with categories: Tools, Workflows, Best Practices, Community Insights"
```

### 5. Follow-up Fetches
For promising GitHub repos or articles found, use WebFetch to extract detailed information:
- GitHub READMEs: Extract features, installation, how it works
- Blog posts: Extract key insights and actionable tips
- Documentation: Extract relevant patterns and examples

## Output Format

Compile findings into these categories:

### Tools & Projects
- Name, link, brief description
- Why it's interesting
- How it could help

### Workflows & Patterns
- Workflow name
- Key steps
- When to use it

### Community Insights
- Notable tips from Twitter/blogs
- Common patterns people are using
- Emerging trends

### Deep Dive Summary
- Include the deep research findings
- Highlight most actionable insights

### Recommendations
- Top 3-5 things worth exploring further
- Suggest next steps or tools to try

Be concise but thorough. Focus on practical, actionable findings.
