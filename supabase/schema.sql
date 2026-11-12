-- App Criticality Assessment: Supabase schema
-- Run this once in Supabase: SQL Editor → New query → paste → Run.
-- Before running, replace YOUR-EMAIL@example.com at the bottom with the facilitator's email.
-- Safe to run again: it only creates what is missing and refreshes the policies.

create extension if not exists pgcrypto;

-- People who get the facilitator view (add applications, reveal, agree, see all answers, export)
create table if not exists public.admins (
  email text primary key
);

-- Applications being assessed
create table if not exists public.apps (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  area         text not null default '',
  owner        text not null default '',
  session_date text not null default '',
  status       text not null default 'not_started',
  final        jsonb,                       -- the agreed result, saved from the Compare page
  created_at   timestamptz not null default now()
);

-- Status: not_started → open (participants can answer) → revealed → agreed
alter table public.apps drop constraint if exists apps_status_check;
alter table public.apps add  constraint apps_status_check check (status in ('not_started', 'open', 'revealed', 'agreed'));
alter table public.apps alter column status set default 'not_started';

-- One answer per participant per application
create table if not exists public.responses (
  app_id       uuid not null references public.apps(id) on delete cascade,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name         text not null,
  ratings      jsonb not null default '{}'::jsonb,   -- {ops, cust, fin, legal, rep}: 0 Low, 1 Medium, 2 Critical
  mtpd         double precision,                      -- hours
  rto          double precision,                      -- hours
  rpo          double precision,                      -- hours
  submitted_at timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  primary key (app_id, user_id)
);

-- Snapshot of answers the facilitator revealed to the group
create table if not exists public.reveals (
  app_id      uuid primary key references public.apps(id) on delete cascade,
  revealed_at timestamptz not null default now(),
  entries     jsonb not null default '[]'::jsonb
);

-- Data checks: only the values the app offers can be stored (also blocks script injection through answers)
create or replace function public.valid_ratings(r jsonb)
returns boolean
language sql
immutable
as $$
  select jsonb_typeof(r) = 'object'
     and not exists (
       select 1 from jsonb_each(r) e
       where e.key not in ('ops', 'cust', 'fin', 'legal', 'rep')
          or e.value not in ('0'::jsonb, '1'::jsonb, '2'::jsonb)
     );
$$;

alter table public.responses drop constraint if exists responses_ratings_valid;
alter table public.responses add  constraint responses_ratings_valid check (public.valid_ratings(ratings));
alter table public.responses drop constraint if exists responses_name_len;
alter table public.responses add  constraint responses_name_len check (char_length(name) between 1 and 100);
alter table public.responses drop constraint if exists responses_times_valid;
alter table public.responses add  constraint responses_times_valid check (
  (mtpd is null or mtpd in (2, 8, 24, 72)) and
  (rto  is null or rto  in (1, 2, 4, 8, 24, 72)) and
  (rpo  is null or rpo  in (0, 0.25, 1, 4, 24))
);

-- Is the signed-in user a facilitator?
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
grant execute on function public.is_admin() to anon, authenticated;

-- Row-level security: this is what keeps answers blind
alter table public.admins    enable row level security;   -- no policies: not readable through the API
alter table public.apps      enable row level security;
alter table public.responses enable row level security;
alter table public.reveals   enable row level security;

drop policy if exists "apps read"            on public.apps;
drop policy if exists "apps insert"          on public.apps;
drop policy if exists "apps update"          on public.apps;
drop policy if exists "apps delete"          on public.apps;
drop policy if exists "responses read"       on public.responses;
drop policy if exists "responses insert"     on public.responses;
drop policy if exists "responses update"     on public.responses;
drop policy if exists "responses delete"     on public.responses;
drop policy if exists "reveals read"         on public.reveals;
drop policy if exists "reveals write"        on public.reveals;

-- Applications: everyone signed in reads; only facilitators change
create policy "apps read"   on public.apps for select to authenticated using (true);
create policy "apps insert" on public.apps for insert to authenticated with check (public.is_admin());
create policy "apps update" on public.apps for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "apps delete" on public.apps for delete to authenticated using (public.is_admin());

-- Answers: each person reads only their own; facilitators read all.
-- Answers can be written only by their owner, and only while the application is still collecting answers.
create policy "responses read" on public.responses for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy "responses insert" on public.responses for insert to authenticated
  with check (user_id = auth.uid()
              and exists (select 1 from public.apps a where a.id = app_id and a.status = 'open'));
create policy "responses update" on public.responses for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid()
              and exists (select 1 from public.apps a where a.id = app_id and a.status = 'open'));
create policy "responses delete" on public.responses for delete to authenticated
  using (public.is_admin());

-- Revealed answers: only facilitators read and write (participants don't see the Compare page)
create policy "reveals read"  on public.reveals for select to authenticated using (public.is_admin());
create policy "reveals write" on public.reveals for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.apps, public.responses, public.reveals to authenticated;

-- Facilitator(s): replace with your email (add more lines for more facilitators)
insert into public.admins (email) values ('YOUR-EMAIL@example.com') on conflict do nothing;
