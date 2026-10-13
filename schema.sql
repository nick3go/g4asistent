-- G4 Asistent: zaženi v Supabase SQL Editorju v izbranem obstoječem projektu.
-- Imena tabel so namenoma prefiksirana, da se ne mešajo z ostalimi aplikacijami.
create table if not exists public.g4_grades (
  id bigint generated always as identity primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  subject text not null check (subject in ('slo','mat','fiz','ang','nem','rač','rso','ele','esi','psim','fizm','zgom','špo')),
  type text not null check (type in ('pisno','ustno','izdelek')),
  value smallint not null check (value between 1 and 5),
  date date not null,
  created_at timestamptz not null default now()
);
create index if not exists g4_grades_owner_date_idx on public.g4_grades(owner_id,date desc);
alter table public.g4_grades enable row level security;
revoke all on public.g4_grades from anon, authenticated;
grant select,insert,update,delete on public.g4_grades to authenticated;
grant usage,select on sequence public.g4_grades_id_seq to authenticated;
drop policy if exists "g4_read_own" on public.g4_grades;
drop policy if exists "g4_insert_own" on public.g4_grades;
drop policy if exists "g4_update_own" on public.g4_grades;
drop policy if exists "g4_delete_own" on public.g4_grades;
create policy "g4_read_own" on public.g4_grades for select to authenticated using ((select auth.uid()) = owner_id);
create policy "g4_insert_own" on public.g4_grades for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "g4_update_own" on public.g4_grades for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "g4_delete_own" on public.g4_grades for delete to authenticated using ((select auth.uid()) = owner_id);
