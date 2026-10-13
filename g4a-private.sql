-- G4 Asistent: izolirana shema. Ne spreminja timeline_private ali starih public tabel.
-- Varno ponovno izvajanje; brez DROP, TRUNCATE ali DELETE.
begin;
create schema if not exists g4a_private;
revoke all on schema g4a_private from public, anon, authenticated;
create table if not exists g4a_private.users (
 id bigint generated always as identity primary key,
 name text not null unique,
 password text not null,
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
 created_at timestamptz not null default now()
);
create index if not exists g4a_grades_owner_date_idx on g4a_private.grades(owner_id,date desc);
revoke all on all tables in schema g4a_private from public, anon, authenticated;
revoke all on all sequences in schema g4a_private from public, anon, authenticated;
alter table g4a_private.users enable row level security;
alter table g4a_private.grades enable row level security;
create or replace function public.g4a_api(
 p_name text,p_password text,p_action text,p_data jsonb default '{}'::jsonb
) returns jsonb language plpgsql security definer set search_path = ''
as $$
declare uid bigint; v_id bigint; result jsonb;
begin
 p_name := lower(trim(p_name));
 if p_name is null or p_name !~ '^[a-z0-9._-]{3,24}$'
   or p_password is null or length(p_password) not between 1 and 200 then
   return jsonb_build_object('ok',false,'message','Neveljavno ime ali geslo.');
 end if;
 if p_action = 'register' then
   begin
     insert into g4a_private.users(name,password) values(p_name,p_password) returning id into uid;
     return '{"ok":true}'::jsonb;
   exception when unique_violation then
     return '{"ok":false,"message":"Ime je že zasedeno."}'::jsonb;
   end;
 end if;
 select id into uid from g4a_private.users where name=p_name and password=p_password;
 if uid is null then return '{"ok":false,"message":"Napačno ime ali geslo."}'::jsonb; end if;
 if p_action='login' then return '{"ok":true}'::jsonb; end if;
 if p_action='list' then
   select coalesce(jsonb_agg(to_jsonb(g) order by g.date desc,g.id desc),'[]'::jsonb) into result
   from (select id,owner_id,subject,type,value,date from g4a_private.grades where owner_id=uid) g;
   return result;
 end if;
 if p_action='delete' then
   delete from g4a_private.grades where id=(p_data->>'id')::bigint and owner_id=uid;
   return jsonb_build_object('ok',found);
 end if;
 if p_action in ('insert','update') then
   if coalesce(p_data->>'subject','') not in ('slo','mat','fiz','ang','nem','rač','rso','ele','esi','psim','fizm','zgom','špo')
     or coalesce(p_data->>'type','') not in ('pisno','ustno','izdelek')
     or coalesce(p_data->>'value','') not in ('1','2','3','4','5')
     or coalesce(p_data->>'date','') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}   then return '{"ok":false,"message":"Neveljavni podatki ocene."}'::jsonb; end if;
   if p_action='insert' then
     insert into g4a_private.grades(owner_id,subject,type,value,date)
     values(uid,p_data->>'subject',p_data->>'type',(p_data->>'value')::smallint,(p_data->>'date')::date)
     returning id into v_id;
   else
     update g4a_private.grades set subject=p_data->>'subject',type=p_data->>'type',
       value=(p_data->>'value')::smallint,date=(p_data->>'date')::date
       where id=(p_data->>'id')::bigint and owner_id=uid returning id into v_id;
   end if;
   return jsonb_build_object('ok',v_id is not null);
 end if;
 return '{"ok":false,"message":"Neznana operacija."}'::jsonb;
end; $$;
revoke all on function public.g4a_api(text,text,text,jsonb) from public;
grant execute on function public.g4a_api(text,text,text,jsonb) to anon,authenticated;
commit;

   then return '{"ok":false,"message":"Neveljavni podatki ocene."}'::jsonb; end if;
   if p_action='insert' then
     insert into g4a_private.grades(owner_id,subject,type,value,date)
     values(uid,p_data->>'subject',p_data->>'type',(p_data->>'value')::smallint,(p_data->>'date')::date)
     returning id into v_id;
   else
     update g4a_private.grades set subject=p_data->>'subject',type=p_data->>'type',
       value=(p_data->>'value')::smallint,date=(p_data->>'date')::date
       where id=(p_data->>'id')::bigint and owner_id=uid returning id into v_id;
   end if;
   return jsonb_build_object('ok',v_id is not null);
 end if;
 return '{"ok":false,"message":"Neznana operacija."}'::jsonb;
end; $$;
revoke all on function public.g4a_api(text,text,text,jsonb) from public;
grant execute on function public.g4a_api(text,text,text,jsonb) to anon,authenticated;
commit;

   then return '{"ok":false,"message":"Neveljavni podatki ocene."}'::jsonb; end if;
   if p_action='insert' then
     insert into g4a_private.grades(owner_id,subject,type,value,date)
     values(uid,p_data->>'subject',p_data->>'type',(p_data->>'value')::smallint,(p_data->>'date')::date)
     returning id into v_id;
   else
     update g4a_private.grades set subject=p_data->>'subject',type=p_data->>'type',
       value=(p_data->>'value')::smallint,date=(p_data->>'date')::date
       where id=(p_data->>'id')::bigint and owner_id=uid returning id into v_id;
   end if;
   return jsonb_build_object('ok',v_id is not null);
 end if;
 return '{"ok":false,"message":"Neznana operacija."}'::jsonb;
end; $$;
revoke all on function public.g4a_api(text,text,text,jsonb) from public;
grant execute on function public.g4a_api(text,text,text,jsonb) to anon,authenticated;
commit;

   then return '{"ok":false,"message":"Neveljavni podatki ocene."}'::jsonb; end if;
   if p_action='insert' then
     insert into g4a_private.grades(owner_id,subject,type,value,date)
     values(uid,p_data->>'subject',p_data->>'type',(p_data->>'value')::smallint,(p_data->>'date')::date)
     returning id into v_id;
   else
     update g4a_private.grades set subject=p_data->>'subject',type=p_data->>'type',
       value=(p_data->>'value')::smallint,date=(p_data->>'date')::date
       where id=(p_data->>'id')::bigint and owner_id=uid returning id into v_id;
   end if;
   return jsonb_build_object('ok',v_id is not null);
 end if;
 return '{"ok":false,"message":"Neznana operacija."}'::jsonb;
end; $$;
revoke all on function public.g4a_api(text,text,text,jsonb) from public;
grant execute on function public.g4a_api(text,text,text,jsonb) to anon,authenticated;
commit;
