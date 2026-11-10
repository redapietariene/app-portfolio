# App Criticality Assessment

A small web tool for running business impact assessments (BIA) of applications with business owners.

Each participant rates an application **on their own** — nobody sees the others' answers until the facilitator reveals them in the meeting. The group then discusses the differences and the facilitator records one agreed result.

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

Each rating has an optional "why" comment, which is shown during the discussion.

## Views

- **Assess** – participants pick an application and submit their answers (editable until the reveal).
- **Compare** – facilitator reveals answers; a side-by-side grid marks each row *Aligned*, *Differs* or *Discuss*; the facilitator sets the agreed values and notes.
- **Results** (facilitator) – all applications and all individual answers in one place, filterable by application, business area, status, criticality and participant role.
- **Applications** (facilitator) – add / delete applications, see answer counts and status.
- **Export to Excel** – `.xlsx` with two sheets: *Agreed results* and *Individual answers* (respects current filters).

## How it runs

`index.html` is a single-page Claude Artifact. It uses the Artifact runtime capabilities:

- `db` – shared storage with access rules:
  - `apps/*`, `reveals/*` – everyone reads, only editors/owner write
  - `responses/<user-id>` – each participant reads and writes only their own document; only the owner can read all of them (that is what keeps the answers blind)
- `user` – identifies the viewer and whether they are the facilitator (artifact owner)
- `downloads` – saving the Excel export

The Excel file is built in the browser with [SheetJS](https://sheetjs.com/) (loaded from cdnjs).

Because it relies on these capabilities, the page works when opened on claude.ai, not as a standalone file.

## Running a session

1. Add the application under **Applications**.
2. Share the artifact with the participants (Contributor within your organization; Editor for people outside it).
3. Everyone fills in **Assess** before or at the start of the meeting.
4. In the meeting open **Compare**, press *Reveal*, discuss the rows marked *Discuss*, then *Save agreed result*.
5. Export from **Results** when all applications are done.
