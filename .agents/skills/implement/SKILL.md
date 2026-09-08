---
name: implement
description: Implement a feature or fix based on a Notion ticket. Fetches ticket details, creates a feature branch, implements the changes, and follows the full development workflow.
allowed-tools: Bash(git:*), Bash(gh:*), Read, Write, Edit, Glob, Grep, WebFetch, mcp__notion__*, mcp__figma__*
---

# Implement Ticket

Implement a feature or fix based on a Notion ticket URL.

**Usage:** `/implement <github-issue-url>`

## Process Overview

1. **Fetch a GitHub issue details** from GitHub
2. **Understand requirements** and acceptance criteria
3. **Create feature branch** with ticket ID
4. **Plan implementation** (enter plan mode for non-trivial changes)
5. **Ask Codex CLI** mcp server to review your plan
6. **Implement changes** following project standards
7. **Ask Codex CLI** mcp server to review your changes
8. **Test thoroughly** (automated + manual)
9. **Report completion** with summary

## Step 1: Fetch Ticket Details

Extract the ticket ID from the URL and fetch details:

```
# Parse Notion URL to get page ID
# Example: https://www.notion.so/equalsgroup/NT-1234-Task-Title-abc123def456

mcp__notion__get_page
- page_id: <extracted-id>
```

Extract:

- **Title** - What needs to be done
- **Description** - Detailed requirements
- **Acceptance criteria** - Definition of done
- **Linked specs** - Related documentation
- **Priority** - Urgency level

## Step 2: Extract and Analyse Figma Designs

Look for Figma links in the ticket body (description field). Common patterns:

- `https://www.figma.com/file/<file-id>/<file-name>`
- `https://www.figma.com/design/<file-id>/<file-name>`

If a Figma link is found, use the Figma MCP tools to extract comprehensive design context:

```
# Step 1: Get structural overview (layer hierarchy, names, positions, sizes)
# Use this first to understand the design structure and identify key node IDs
mcp__figma__get_metadata
- selection_link: <figma-url-with-node-selection>

# Step 2: Get detailed design context for specific components
# Returns styled code output (React + Tailwind by default)
# Includes layout, spacing, typography, colours, and component structure
mcp__figma__get_design_context
- selection_link: <figma-url-with-node-selection>
```

**Working with Figma selection links:**

- Figma URLs with node selections look like: `https://www.figma.com/design/<file-id>/<file-name>?node-id=<node-id>`
- If the ticket only links to a file without node selection, use `get_metadata` first to identify relevant frames/components
- Check for component names, especially for visual elements such as illustrations, icons or flags, and make sure to match them against Geometry
- For large designs, start with `get_metadata` to avoid token limits, then use `get_design_context` on specific nodes

**Validate design matches ticket:**

⚠️ **IMPORTANT**: Figma links in tickets can sometimes be incorrect, outdated, or copied from another ticket by mistake.

Before proceeding, verify the design content matches the ticket requirements:

1. **Check file/page name** - Does it relate to the ticket title?
2. **Review design content** - Does it match what the ticket describes?
3. **Look for inconsistencies** - Are there obvious mismatches?

**Example mismatches to watch for:**

- Ticket: "Add currency display component"
  - ❌ Design shows: Payment card UI
  - ✅ Design shows: Currency selector or currency format examples

- Ticket: "Implement user profile page"
  - ❌ Design shows: Login form
  - ✅ Design shows: User profile layout with avatar, bio, settings

**If mismatch detected:**

```markdown
⚠️ **Warning: Possible Figma link mismatch**

The linked Figma design appears to be for [what it actually shows], but the ticket is about [what ticket describes].

**Please verify:**

- Is this the correct Figma link for this ticket?
- Should I proceed without the design reference?
- Is there a different design I should use?

Waiting for confirmation before proceeding with implementation.
```

**If design matches ticket, extract specifications:**

- **Layout and spacing** - Margins, padding, gaps
- **Typography** - Font families, sizes, weights, line heights
- **Colours** - Hex codes, named colours, design tokens
- **Components** - Reusable UI elements
- **States** - Hover, active, disabled, error states
- **Responsive behaviour** - Breakpoints, mobile/desktop variants
- **Interactions** - Animations, transitions, click targets

**Design-to-code mapping:**

- Identify reusable components vs one-off elements
- Note any design tokens or CSS variables to use
- Check for existing similar components in the codebase
- Highlight any accessibility considerations (contrast, focus states)

**Display confirmation message:**

```markdown
✅ **Figma design verified**

Design content matches ticket requirements. Using design specifications for implementation.

⚠️ **Please double-check**: Review the Figma link yourself to ensure it's the correct design for this ticket.
```

If no Figma link found, proceed without design reference.

## Step 3: Create Feature Branch

```bash
# Ensure we're on the base branch and up to date
git checkout main && git pull origin main
# Or for staged flow:
git checkout develop && git pull origin develop

# Create feature branch
git checkout -b feature/TICKET-ID-brief-description
```

Branch naming: `feature/NT-1234-brief-description` or `fix/NT-1234-brief-description`

## Step 4: Plan Implementation

For non-trivial changes, enter plan mode:

1. **Explore the codebase** - Understand existing patterns
2. **Identify affected files** - What needs to change
3. **Match Figma designs** - If present, plan how to translate design specs to code
4. **Consider edge cases** - What could go wrong
5. **Design the approach** - How to implement
6. **Get user approval** - Before writing code

## Step 5: Implement Changes

Follow the project's coding standards:

- **Read before writing** - Understand existing code first
- **Match Figma designs** - If present, implement exact spacing, colours, typography, and layout
- **Small, focused changes** - Don't over-engineer
- **Follow conventions** - Match existing patterns
- **Handle errors** - Fail fast, log appropriately
- **Security first** - No vulnerabilities (OWASP top 10)

## Step 6: Test Thoroughly

**Automated testing:**

```bash
# Run relevant tests
pnpm test        # or npm test, dotnet test, etc.
pnpm test:lint   # Linting
pnpm test:types  # Type checking
```

**Manual verification:**

- For web code: Use browser MCP to verify visually
- If Figma design was provided: Compare implementation against design specs
- For APIs: Send test requests
- For CLI tools: Run commands manually

## Step 7: Report Completion

Provide a summary:

```markdown
## Implementation Complete: TICKET-ID

### Changes Made

- file1.ts: Added X functionality
- file2.ts: Updated Y to support Z

### Design Implementation

- [x] Figma design analysed and implemented (if applicable)
- Spacing, colours, and typography match design specs
- Responsive behaviour implemented as designed

### Testing

- [x] Unit tests pass
- [x] Integration tests pass
- [x] Manual verification complete
- [x] Visual comparison with Figma design (if applicable)

### Notes

Any important context for reviewers.

---

Ready for `/pr` to create pull request.
```

## Important Rules

- **Validate Figma links** - Always verify design content matches ticket requirements before implementing (where applicable)
- **Never skip testing** - Both automated and manual verification required
- **Follow the ticket scope** - Don't add unrequested features
- **Ask when unclear** - Better to clarify than assume
- **Update ticket status** - Mark as in-progress, then done
- **Link commits to ticket** - Include ticket ID in commit messages

## Prerequisites

What you might need, depending on use case:

1. Notion MCP configured with read access to tickets
2. Figma MCP configured with read access to design files (optional, for design implementation)
3. Git repository with proper branch permissions
4. Understanding of project's test commands (check package.json or similar)

## After Implementation

Suggest next steps:

1. `/commit` - Create a well-structured commit
2. `/pr` - Create or update the pull request
3. Update ticket status in Notion
