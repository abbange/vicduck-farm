-- 오리 농장: 가족 코드로 묶이는 저장소. 테이블은 직접 접근 불가(RLS on, 정책 없음),
-- 아래 함수(security definer)로만 읽고 쓴다. 가족 코드를 모르면 데이터에 접근할 수 없다.
create schema if not exists duckfarm;

create table if not exists duckfarm.families(
  code text primary key check (char_length(code) between 10 and 40),
  created_at timestamptz not null default now()
);
create table if not exists duckfarm.docs(
  code text not null references duckfarm.families(code) on delete cascade,
  key text not null check (key in ('save/main','save/mom','save/dad','gift/kid','gift/mom','gift/dad','homework/current','vocab/current','vocab/stats')),
  val jsonb not null,
  at timestamptz not null default now(),
  primary key(code,key)
);
create table if not exists duckfarm.results(
  id bigint generated always as identity primary key,
  code text not null references duckfarm.families(code) on delete cascade,
  rec jsonb not null,
  at timestamptz not null default now()
);
create index if not exists results_code_at on duckfarm.results(code, at desc);
alter table duckfarm.families enable row level security;
alter table duckfarm.docs enable row level security;
alter table duckfarm.results enable row level security;
revoke all on all tables in schema duckfarm from anon, authenticated;

create or replace function public.df_create_family(p_code text) returns boolean
language plpgsql security definer set search_path = '' as $$
begin
  if p_code !~ '^[A-Z2-9]{10,40}$' then return false; end if;
  insert into duckfarm.families(code) values (p_code) on conflict do nothing;
  return true;
end $$;

create or replace function public.df_check(p_code text) returns boolean
language sql security definer set search_path = '' stable as $$
  select exists(select 1 from duckfarm.families where code = p_code);
$$;

create or replace function public.df_get(p_code text, p_key text) returns jsonb
language sql security definer set search_path = '' stable as $$
  select val from duckfarm.docs where code = p_code and key = p_key;
$$;

create or replace function public.df_set(p_code text, p_key text, p_val jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
begin
  if not exists(select 1 from duckfarm.families where code = p_code) then return false; end if;
  if pg_column_size(p_val) > 500000 then return false; end if;
  insert into duckfarm.docs(code,key,val,at) values (p_code,p_key,p_val,now())
    on conflict (code,key) do update set val = excluded.val, at = now();
  return true;
end $$;

create or replace function public.df_add_result(p_code text, p_rec jsonb) returns boolean
language plpgsql security definer set search_path = '' as $$
begin
  if not exists(select 1 from duckfarm.families where code = p_code) then return false; end if;
  if pg_column_size(p_rec) > 20000 then return false; end if;
  insert into duckfarm.results(code,rec) values (p_code,p_rec);
  delete from duckfarm.results where code = p_code and id not in
    (select id from duckfarm.results where code = p_code order by at desc limit 300);
  return true;
end $$;

create or replace function public.df_results(p_code text, p_n int) returns setof jsonb
language sql security definer set search_path = '' stable as $$
  select rec from duckfarm.results where code = p_code order by at desc limit least(greatest(p_n,1),50);
$$;

revoke all on function public.df_create_family(text), public.df_check(text), public.df_get(text,text),
  public.df_set(text,text,jsonb), public.df_add_result(text,jsonb), public.df_results(text,int) from public;
grant execute on function public.df_create_family(text), public.df_check(text), public.df_get(text,text),
  public.df_set(text,text,jsonb), public.df_add_result(text,jsonb), public.df_results(text,int) to anon, authenticated;

-- 쉬운 가족 코드(별명): 짧은 코드 → 원래 긴 코드로 연결. 기기에는 긴 코드가 저장된다.
create table if not exists duckfarm.aliases(
  alias text primary key check (alias ~ '^[A-Z0-9가-힣]{4,12}$'),
  code text not null unique references duckfarm.families(code) on delete cascade,
  at timestamptz not null default now()
);
alter table duckfarm.aliases enable row level security;
revoke all on duckfarm.aliases from anon, authenticated;
create or replace function public.df_resolve(p_alias text) returns text
language sql security definer set search_path = '' stable as $$
  select code from duckfarm.aliases where alias = upper(p_alias);
$$;
create or replace function public.df_get_alias(p_code text) returns text
language sql security definer set search_path = '' stable as $$
  select alias from duckfarm.aliases where code = p_code;
$$;
create or replace function public.df_set_alias(p_code text, p_alias text) returns text
language plpgsql security definer set search_path = '' as $$
declare a text := upper(p_alias);
begin
  if not exists(select 1 from duckfarm.families where code = p_code) then return 'nocode'; end if;
  if a !~ '^[A-Z0-9가-힣]{4,12}$' then return 'bad'; end if;
  if exists(select 1 from duckfarm.families where code = a) then return 'taken'; end if;
  if exists(select 1 from duckfarm.aliases where alias = a and code <> p_code) then return 'taken'; end if;
  insert into duckfarm.aliases(alias,code) values (a,p_code)
    on conflict (code) do update set alias = excluded.alias, at = now();
  return 'ok';
end $$;
revoke all on function public.df_resolve(text), public.df_get_alias(text), public.df_set_alias(text,text) from public;
grant execute on function public.df_resolve(text), public.df_get_alias(text), public.df_set_alias(text,text) to anon, authenticated;
