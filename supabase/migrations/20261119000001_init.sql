-- Budget Tara x Mattel
-- Satu tabel dokumen (col + id + data jsonb) mengikuti struktur aplikasi, plus daftar anggota.
-- Hanya email yang terdaftar di public.members yang bisa membaca/menulis.

create table if not exists public.members (
  email      text primary key check (email = lower(email)),
  who        text not null check (who in ('a','b')),
  created_at timestamptz not null default now()
);

create table if not exists public.docs (
  col        text not null,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (col, id)
);

create or replace function public.rk_touch() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists docs_touch on public.docs;
create trigger docs_touch before insert or update on public.docs
for each row execute function public.rk_touch();

-- Fungsi cek anggota di skema privat (tidak terekspos lewat API)
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create or replace function private.is_member() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.members m
    where m.email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  );
$$;
revoke all on function private.is_member() from public, anon;
grant execute on function private.is_member() to authenticated;

alter table public.members enable row level security;
alter table public.docs    enable row level security;

create policy "members: anggota bisa lihat" on public.members
  for select to authenticated using ((select private.is_member()));

create policy "docs: anggota baca"  on public.docs for select to authenticated using ((select private.is_member()));
create policy "docs: anggota tulis" on public.docs for insert to authenticated with check ((select private.is_member()));
create policy "docs: anggota ubah"  on public.docs for update to authenticated using ((select private.is_member())) with check ((select private.is_member()));
create policy "docs: anggota hapus" on public.docs for delete to authenticated using ((select private.is_member()));

revoke all on public.docs, public.members from anon;
grant select, insert, update, delete on public.docs to authenticated;
grant select on public.members to authenticated;

-- Realtime: perubahan dari pasangan langsung muncul
do $$ begin
  alter publication supabase_realtime add table public.docs;
exception when duplicate_object then null; end $$;
