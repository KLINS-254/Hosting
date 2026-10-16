-- TICOH BOT HOSTING starter schema
-- Run in Supabase SQL Editor. Review before production.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.hosting_plans (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  monthly_price_ksh integer not null default 0 check (monthly_price_ksh >= 0),
  features jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.servers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  runtime text not null check (runtime in ('Node.js','Python')),
  desired_state text not null default 'stopped' check (desired_state in ('running','stopped')),
  runtime_status text not null default 'not_connected'
    check (runtime_status in ('not_connected','queued','starting','online','stopping','offline','crashed','error')),
  worker_instance_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists servers_owner_created_idx on public.servers(owner_id, created_at desc);

create table if not exists public.deployments (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null check (source_type in ('zip','github')),
  source_reference text,
  status text not null default 'queued',
  build_log_location text,
  created_at timestamptz not null default now()
);
create index if not exists deployments_owner_created_idx on public.deployments(owner_id, created_at desc);

create table if not exists public.server_files_metadata (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  relative_path text not null,
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  updated_at timestamptz not null default now(),
  unique(server_id, relative_path)
);

create table if not exists public.environment_variables (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  variable_name text not null,
  encrypted_value_reference text not null,
  created_at timestamptz not null default now(),
  unique(server_id, variable_name)
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  plan_id uuid references public.hosting_plans(id),
  status text not null default 'pending' check (status in ('pending','active','past_due','cancelled','expired')),
  provider_subscription_id text,
  current_period_end timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  amount_ksh integer not null check (amount_ksh >= 0),
  currency text not null default 'KES',
  status text not null default 'pending' check (status in ('pending','verified','failed','refunded')),
  provider_reference text unique,
  created_at timestamptz not null default now()
);

create table if not exists public.backups (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  storage_object_key text not null,
  size_bytes bigint not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.usage_metrics (
  id bigint generated always as identity primary key,
  server_id uuid not null references public.servers(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  cpu_percent numeric,
  memory_bytes bigint,
  storage_bytes bigint,
  measured_at timestamptz not null default now()
);
create index if not exists usage_metrics_owner_time_idx on public.usage_metrics(owner_id, measured_at desc);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject text not null,
  message text not null,
  status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  resource_type text,
  resource_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- RLS: owner-level access only. Admin access must be added with a trusted,
-- server-side role mechanism; never trust a client-provided admin flag.
alter table public.profiles enable row level security;
alter table public.hosting_plans enable row level security;
alter table public.servers enable row level security;
alter table public.deployments enable row level security;
alter table public.server_files_metadata enable row level security;
alter table public.environment_variables enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payments enable row level security;
alter table public.backups enable row level security;
alter table public.usage_metrics enable row level security;
alter table public.support_tickets enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists "profiles select own" on public.profiles;
create policy "profiles select own" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "profiles update own" on public.profiles;
create policy "profiles update own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "plans visible when active" on public.hosting_plans;
create policy "plans visible when active" on public.hosting_plans for select using (active = true);

drop policy if exists "servers owner access" on public.servers;
create policy "servers owner access" on public.servers for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "deployments owner access" on public.deployments;
create policy "deployments owner access" on public.deployments for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "files metadata owner access" on public.server_files_metadata;
create policy "files metadata owner access" on public.server_files_metadata for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "environment owner access" on public.environment_variables;
create policy "environment owner access" on public.environment_variables for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "subscriptions owner read" on public.subscriptions;
create policy "subscriptions owner read" on public.subscriptions for select to authenticated using (owner_id = auth.uid());
drop policy if exists "payments owner read" on public.payments;
create policy "payments owner read" on public.payments for select to authenticated using (owner_id = auth.uid());
drop policy if exists "backups owner access" on public.backups;
create policy "backups owner access" on public.backups for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
drop policy if exists "usage owner read" on public.usage_metrics;
create policy "usage owner read" on public.usage_metrics for select to authenticated using (owner_id = auth.uid());
drop policy if exists "tickets owner access" on public.support_tickets;
create policy "tickets owner access" on public.support_tickets for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Intentionally no client policies for audit_logs or secret environment values.
-- Use a trusted backend to write audit events and decrypt environment secrets.
