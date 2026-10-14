-- G4Asistent: enkratna namestitev v NOVEM ali ze obstojecem Supabase projektu.
-- Ustvari samo objekte G4A. NE brise ali spreminja timeline_private.
-- Ne izvajaj za nadgradnjo obstojece instalacije (za ta namen uporabi migracije iz zgodovine Git).
-- G4 Asistent: izolirana shema. Ne spreminja timeline_private ali starih public tabel.
-- Varno ponovno izvajanje; brez DROP, TRUNCATE ali DELETE.
begin;
create schema if not exists g4a_private;
revoke all on schema g4a_private from public, anon, authenticated;
create table if not exists g4a_private.users (
 id bigint generated always as identity primary key,
 name text not null unique,
 password text not null,
 class_name text not null default 'G4A' check (length(class_name) between 1 and 60),
 created_at timestamptz not null default now(),
 constraint g4a_users_name_format check (name ~ '^[a-z0-9._-]{3,24}$'),
 constraint g4a_users_password_length check (length(password) between 1 and 200)
);
create table if not exists g4a_private.grades (
 id bigint generated always as identity primary key,
 owner_id bigint not null references g4a_private.users(id) on delete cascade,
 subject text not null check (subject in ('slo','mat','fiz','ang','nem','rač','rso','ele','esi','psim','fizm','zgom','špo')),
 type text not null check (type in ('pisno','ustno','izdelek')),
 value smallint not null check (value between 1 and 5),
 date date not null,
 percent numeric(5,2) check (percent between 0 and 100),
 correction_of bigint references g4a_private.grades(id) on delete set null,
 created_at timestamptz not null default now()
);
create unique index if not exists g4a_one_correction_per_grade on g4a_private.grades(correction_of) where correction_of is not null;
create index if not exists g4a_grades_owner_date_idx on g4a_private.grades(owner_id,date desc);
revoke all on all tables in schema g4a_private from public, anon, authenticated;
revoke all on all sequences in schema g4a_private from public, anon, authenticated;
alter table g4a_private.users enable row level security;
alter table g4a_private.grades enable row level security;

-- Ocenjevanja so ločena od osebnih ocen.
create table if not exists g4a_private.assessments (
 id bigint generated always as identity primary key,
 class_name text not null check(length(class_name) between 1 and 60),
 subject text not null check(subject in ('slo','mat','ang','nem','fiz','rač','rso','ele','esi','špo','fizm','psim','zgom')),
 type text not null check(type in ('pisno','ustno','izdelek')),
 date date not null,
 created_at timestamptz not null default now()
);
create index if not exists g4a_assessments_class_date_idx on g4a_private.assessments(class_name,date);
alter table g4a_private.assessments enable row level security;
revoke all on g4a_private.assessments from public,anon,authenticated;
-- Administratorsko geslo se preverja z enostavno primerjavo nizov.
create or replace function public.g4a_admin(p_password text,p_action text,p_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path=''
as $admin$
declare chosen_id bigint;
begin
 if coalesce(p_password,'') <> 'v3g0v4' then
   return jsonb_build_object('ok',false,'message','Napačno geslo.');
 end if;
 if p_action='login' then return jsonb_build_object('ok',true); end if;
 if p_action='list' then
 delete from g4a_private.assessments where date < current_date-6;
 return jsonb_build_object('ok',true,'items',coalesce((
 select jsonb_agg(to_jsonb(a) order by a.date desc,a.id desc) from
 (select id,class_name,subject,type,date from g4a_private.assessments where date>=current_date-6) a
 ),'[]'::jsonb)); end if;
 if p_action='add' then
 if coalesce(p_data->>'class_name','')='' or length(p_data->>'class_name')>60
 or coalesce(p_data->>'subject','') not in ('slo','mat','ang','nem','fiz','rač','rso','ele','esi','špo','fizm','psim','zgom')
 or coalesce(p_data->>'type','') not in ('pisno','ustno','izdelek')
 or coalesce(p_data->>'date','') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
 then return jsonb_build_object('ok',false,'message','Preveri podatke.'); end if;
 insert into g4a_private.assessments(class_name,subject,type,date)
 values(trim(p_data->>'class_name'),p_data->>'subject',p_data->>'type',(p_data->>'date')::date)
 returning id into chosen_id;
 return jsonb_build_object('ok',true,'id',chosen_id);
 end if;
 if p_action='delete' then
 delete from g4a_private.assessments where id=(p_data->>'id')::bigint;
 return jsonb_build_object('ok',found);
 end if;
 return jsonb_build_object('ok',false,'message','Neznano dejanje.');
end;
$admin$;
revoke all on function public.g4a_admin(text,text,jsonb) from public;
grant execute on function public.g4a_admin(text,text,jsonb) to anon,authenticated;

create or replace function public.g4a_api(p_name text,p_password text,p_action text,p_data jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path = ''
as $body$
declare uid bigint; v_id bigint; result jsonb; correction bigint; pct numeric;
begin
 p_name := lower(trim(p_name));
 if p_name is null or p_name !~ '^[a-z0-9._-]{3,24}$'
 or p_password is null or length(p_password) not between 1 and 200 then
   return jsonb_build_object('ok',false,'message','Neveljavno ime ali geslo.');
 end if;
 if p_action='register' then
   if length(coalesce(p_data->>'class_name',''))>60 then return jsonb_build_object('ok',false,'message','Razred je predolg.'); end if;
   begin
     insert into g4a_private.users(name,password,class_name) values(p_name,p_password,coalesce(nullif(trim(p_data->>'class_name'),''),'G4A')) returning id into uid;
     return jsonb_build_object('ok',true);
   exception when unique_violation then
     return jsonb_build_object('ok',false,'message','Ime je že zasedeno.');
   end;
 end if;
 select id into uid from g4a_private.users where name=p_name and password=p_password;
 if uid is null then return jsonb_build_object('ok',false,'message','Napačno ime ali geslo.'); end if;
 if p_action='login' then return jsonb_build_object('ok',true); end if;
 if p_action='list' then
   select coalesce(jsonb_agg(to_jsonb(g) order by g.date desc,g.id desc),'[]'::jsonb) into result
   from (select id,owner_id,subject,type,value,date,percent,correction_of from g4a_private.grades where owner_id=uid) g;
   return result;
 end if;
 if p_action='class_stats' then
   -- Branje samo pisnih ocen istega razreda; brez imen, gesel ali ID uporabnikov.
   select jsonb_build_object(
     'class_name', (select class_name from g4a_private.users where id=uid),
     'grades', coalesce((
       select jsonb_agg(jsonb_build_object('subject',g.subject,'date',g.date,'value',g.value,'percent',g.percent) order by g.date,g.subject)
       from g4a_private.grades g
       join g4a_private.users student on student.id=g.owner_id
       where student.class_name=(select self.class_name from g4a_private.users self where self.id=uid)
         and g.type='pisno' and g.correction_of is null
     ),'[]'::jsonb)
   ) into result;
   return result;
 end if;
 if p_action='assessments' then
   delete from g4a_private.assessments where date < current_date - 6;
   return jsonb_build_object('ok',true,'items',coalesce((
     select jsonb_agg(to_jsonb(a) order by a.date,a.id)
     from (select id,subject,type,date from g4a_private.assessments
       where class_name=(select class_name from g4a_private.users where id=uid)
       and date>=current_date-6) a
   ),'[]'::jsonb));
 end if;
 if p_action='delete' then
   delete from g4a_private.grades where id=(p_data->>'id')::bigint and owner_id=uid;
   return jsonb_build_object('ok',found);
 end if;
 if p_action in ('insert','update') then
   if coalesce(p_data->>'subject','') not in ('slo','mat','fiz','ang','nem','rač','rso','ele','esi','psim','fizm','zgom','špo')
   or coalesce(p_data->>'type','') not in ('pisno','ustno','izdelek')
   or coalesce(p_data->>'value','') not in ('1','2','3','4','5')
   or coalesce(p_data->>'date','') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
   then return jsonb_build_object('ok',false,'message','Neveljavni podatki ocene.'); end if;
   if nullif(p_data->>'percent','') is not null then
     if (p_data->>'percent') !~ '^[0-9]{1,3}([.][0-9]{1,2})?$'
     then return jsonb_build_object('ok',false,'message','Neveljavni procenti.'); end if;
     pct := (p_data->>'percent')::numeric;
     if pct>100 then return jsonb_build_object('ok',false,'message','Procenti morajo biti med 0 in 100.'); end if;
   else pct := null;
   end if;
   correction:=nullif(p_data->>'correction_of','')::bigint;
   if p_action='insert' and correction is not null then
     if not exists(select 1 from g4a_private.grades original
       where original.id=correction and original.owner_id=uid
       and original.correction_of is null and original.subject=p_data->>'subject')
     then return jsonb_build_object('ok',false,'message','Neveljavna izvirna ocena.'); end if;
   end if;
   if p_action='insert' then
     insert into g4a_private.grades(owner_id,subject,type,value,date,percent,correction_of)
     values(uid,p_data->>'subject',p_data->>'type',(p_data->>'value')::smallint,(p_data->>'date')::date,pct,correction)
     returning id into v_id;
   else
     update g4a_private.grades set subject=p_data->>'subject',type=p_data->>'type',
     value=(p_data->>'value')::smallint,date=(p_data->>'date')::date,percent=pct
     where id=(p_data->>'id')::bigint and owner_id=uid returning id into v_id;
   end if;
   return jsonb_build_object('ok',v_id is not null);
 end if;
 return jsonb_build_object('ok',false,'message','Neznana operacija.');
end;
$body$;
revoke all on function public.g4a_api(text,text,text,jsonb) from public;
grant execute on function public.g4a_api(text,text,text,jsonb) to anon, authenticated;
-- Samodejno čiščenje, če je pg_cron v Supabase omogočen.
do $schedule$
begin
 if exists(select 1 from pg_extension where extname='pg_cron') then
   if not exists(select 1 from cron.job where jobname='g4a_assessment_cleanup') then
     perform cron.schedule('g4a_assessment_cleanup','10 0 * * *',
     'delete from g4a_private.assessments where date < current_date - 6');
   end if;
 end if;
end;
$schedule$;
commit;
