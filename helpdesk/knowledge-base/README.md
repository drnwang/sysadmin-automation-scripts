# Help Desk Knowledge Base

Write a set of knowledge base (KB) articles and standard operating procedures (SOPs) that a new Tier 1 technician could follow without asking anyone. This folder contains 10 finished articles for the `lab.local` environment, plus the template and the method behind them.

> **Status:** 10 articles written for the lab. Test each one in the lab, add screenshots, and adjust anything that doesn't match what you see.

| | |
|---|---|
| **Role** | Help desk |
| **Time** | 2 evenings to test and polish |
| **Cost** | Free |
| **Builds on** | [Server lab](../../windows/server-lab/), [osTicket lab](../ticketing-osticket/) |
| **Resume keywords** | Technical writing, SOPs, knowledge management, end-user communication |

## Why this matters

Most help desk candidates say they have "strong communication skills." Few can **show** it. A folder of clear, tested KB articles proves you can explain technical fixes to non-technical people and help your team resolve tickets faster. Many service desks measure "first contact resolution," and good KB articles are how teams raise it.

---

## The articles

| ID | Article | Audience |
|---|---|---|
| [KB-001](./KB-001-password-reset-and-unlock.md) | Reset a password or unlock an account | Technicians |
| [KB-002](./KB-002-mfa-new-phone.md) | Set up MFA on a new phone | End users + technicians |
| [KB-003](./KB-003-vpn-wont-connect.md) | VPN won't connect | End users + technicians |
| [KB-004](./KB-004-mapped-drive-missing.md) | Mapped drive missing or "access denied" | Technicians |
| [KB-005](./KB-005-printer-offline.md) | Printer offline or jobs stuck | Technicians |
| [KB-006](./KB-006-outlook-password-prompts.md) | Outlook keeps asking for a password | Technicians |
| [KB-007](./KB-007-slow-computer.md) | Computer is slow | Technicians |
| [KB-008](./KB-008-report-phishing.md) | Report a suspicious email | End users + technicians |
| [KB-009](./KB-009-new-hire-setup.md) | New hire setup checklist | Technicians (SOP) |
| [KB-010](./KB-010-departure-checklist.md) | Employee departure checklist | Technicians (SOP) |

---

## How to write a good KB article

### The template
Every article uses the same sections, so readers always know where to look:

```markdown
# KB-000: Title written as the problem the user has

| | |
|---|---|
| **Applies to** | Systems or versions |
| **Audience** | End users / Technicians |
| **Time to fix** | Typical duration |
| **Last tested** | Date, environment |

## Symptoms
What the user sees, including exact error messages (people search for these).

## Before you start
Identity verification, permissions needed, what to have ready.

## Fix
Numbered steps. One action per step. Bold the exact button and menu names.

## If that didn't work
The next most likely causes, in order.

## Escalate when
Clear conditions for moving the ticket to Tier 2, and what to include.

## Related
Links to related articles.
```

### Rules the articles follow
1. **Title = the user's problem**, in their words ("Printer offline"), not the fix ("Restart Print Spooler").
2. **Quote the exact error message.** That's what people type into search.
3. **One action per numbered step.** Bold the exact names of buttons and menus.
4. **Say why, briefly,** when it helps someone avoid a mistake.
5. **Always include "Escalate when."** A Tier 1 tech should never be stuck guessing.
6. **Record when it was last tested.** Old KB articles cause more tickets than they solve.

---

## Tutorial: test, polish, and publish

### Part 1: Test each article in the lab
Work through each article in your `lab.local` environment as if you were a new technician who had never seen it:
1. Recreate the problem. For example, lock `jsmith` by entering a wrong password 5 times on CLIENT01.
2. Follow the article **exactly as written**, step by step.
3. Fix any step that's unclear, out of order, or doesn't match what you see on screen.
4. Take a screenshot at the key steps and add it under the step.
5. Update **Last tested** with today's date.

### Part 2: Publish to osTicket
If you've done the [osTicket lab](../ticketing-osticket/):
1. **Agent Panel → Knowledgebase → Categories → Add New Category**: *Accounts & Sign-in*, *Network & Access*, *Printing*, *Security*, *Onboarding & Offboarding*. Mark them **Public** if users should see them.
2. **Knowledgebase → FAQs → Add New FAQ**: paste each article's content into the matching category.
3. Link articles from your ticket resolutions, as in the [sample resolution note](../ticketing-osticket/mock-tickets.md#sample-resolution-note).

### Part 3: Measure it
While working the [mock ticket queue](../ticketing-osticket/mock-tickets.md), count how many tickets you solved using only a KB article. Write down any ticket that **should** have had an article, and write that article next.

## How to talk about it in an interview

> *"I wrote and tested a set of KB articles and SOPs for my lab environment, covering lockouts, MFA, VPN, mapped drives, printers, phishing reports, and onboarding and offboarding checklists. Every article has a clear 'escalate when' section, so a new Tier 1 tech knows exactly when to hand off and what to include."*
