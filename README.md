# App Criticality Assessment

A small web tool for running business impact assessments (BIA) of applications with business owners.

Each participant rates an application **on their own**. Nobody sees the others' answers until the facilitator reveals them in the meeting. The group then discusses the differences and the facilitator records one agreed result.

- **Live app:** https://redapietariene.github.io/app-portfolio/ (after GitHub Pages is switched on, see setup)
- **Data:** stored in Supabase (Postgres) with row-level security

## What it assesses

| Area | Scale |
|---|---|
| Business operations impact | Low / Medium / Critical |
| Customers affected | Low / Medium / Critical |
| Financial impact | Low / Medium / Critical |
| Legal / compliance impact | Low / Medium / Critical |
| Reputation impact | Low / Medium / Critical |
| **Overall criticality** | Highest of the five areas |
| MTPD – maximum tolerable period of disruption | 2 h / 8 h / 24 h / more than 24 h |
| RTO – recovery time objective | 1 h … 3 days (warns if longer than MTPD) |
| RPO – recovery point objective (data loss) | none … 24 h |

## Proposed SLA level

After the facilitator saves the agreed result, Compare and Results show a **proposed SLA level** (also in the Excel export). It takes the stricter of:
- overall criticality: Critical → Level 1, Medium → Level 2, Low → Level 3
- agreed RTO against each level's disaster recovery time: up to 4 hours → Level 1, up to 8 hours → Level 2, longer → Level 3

The SLA table is a draft. Its values and the rule live at the top of the script in `index.html` (`SLA` and `proposeSla`). The proposal is calculated on the fly, so changing them updates every application.

## Who sees what

| | Participant | Facilitator |
|---|---|---|
| Sign-in | Types their name (no account, no password) | Email sign-in link; email must be in the `admins` table |
| Applications page | Answers open applications, one question per card | Sees application tiles; adds, deletes, opens or stops each assessment (doesn't answer) |
| Compare | – | Reveals, discusses, saves the agreed result |
| Results + Excel export | – | All applications, filters, `.xlsx` export |

Blind answers are enforced by the database, not just hidden by the page: a participant can only read their own answers, and can only write while the application is still collecting answers.

## Setup (one time)

### 1. Create the tables in Supabase
1. Open the Supabase project → **SQL Editor** → **New query**.
2. Paste the contents of [`supabase/schema.sql`](supabase/schema.sql).
3. At the bottom, replace `YOUR-EMAIL@example.com` with the facilitator's email.
4. Click **Run**.

### 2. Switch on sign-in
In Supabase → **Authentication**:
- **Sign In / Providers** → turn on **Allow anonymous sign-ins** (this is how participants join by name). **Email** stays on (facilitator sign-in).
- **URL Configuration** → set **Site URL** to `https://redapietariene.github.io/app-portfolio/` and add the same address under **Redirect URLs**.

### 3. Publish the page
GitHub repo → **Settings** → **Pages** → Source: **Deploy from a branch**, branch `main`, folder `/ (root)` → **Save**. The link appears after a minute or two.

## Running a session

1. Facilitator signs in with email, adds the application (**+ Add application**) and clicks **Open assessment** when participants are ready. New applications start as *Not started*, and participants can't answer them until then.
2. Send participants the link. They type their name and answer (about 2 minutes).
3. In the meeting open **Compare** → **Reveal answers**, discuss the rows marked *Discuss*, set the agreed values → **Save agreed result**.
4. When all applications are done: **Results** → **Export to Excel**.

## Good to know

- Participants come back in the **same browser** to change answers before the reveal (their sign-in is remembered there).
- Supabase limits anonymous sign-ins to 30 per hour per IP address by default. If a whole office joins at once from one network, raise it under **Authentication → Rate Limits**.
- Supabase's built-in email sender only sends a few emails per hour. That's fine for the facilitator's sign-in link.
- The Supabase publishable key in `index.html` is meant to be public. Access is controlled by the row-level security rules in `schema.sql`.

## Files

- `index.html` – the app (single page, no build step)
- `supabase/schema.sql` – tables, access rules and facilitator list
- `claude-artifact/index.html` – the earlier version that ran as a Claude artifact
