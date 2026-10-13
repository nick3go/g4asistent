-- Migracija G4Asistent v2. Brez sprememb Timeline in brez brisanja ocen.
begin;
alter table g4a_private.grades add column if not exists percent numeric(5,2);
alter table g4a_private.grades add column if not exists correction_of bigint references g4a_private.grades(id) on delete set null;
create unique index if not exists g4a_one_correction_per_grade on g4a_private.grades(correction_of) where correction_of is not null;
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
   from (select id,owner_id,subject,type,value,date,percent,correction_of from g4a_private.grades where owner_id=uid) g;
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
     or coalesce(p_data->>'date','') !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}
   then return '{"ok":false,"message":"Neveljavni podatki ocene."}'::jsonb; end if;
   if nullif(p_data->>'correction_of','') is not null then
     if not exists (select 1 from g4a_private.grades parent
       where parent.id=(p_data->>'correction_of')::bigint and parent.owner_id=uid
       and parent.correction_of is null and parent.subject=p_data->>'subject'
       and (p_action='update' or not exists(select 1 from g4a_private.grades child where child.correction_of=parent.id)))
     then return '{"ok":false,"message":"Neveljavna ali že popravljena ocena."}'::jsonb; end if;
   end if;
   if p_action='insert' then
     insert into g4a_private.grades(owner_id,subject,type,value,date,percent,correction_of)
     values(uid,p_data->>'subject',p_data->>'type',(p_data->>'value')::smallint,(p_data->>'date')::date,nullif(p_data->>'percent','')::numeric,nullif(p_data->>'correction_of','')::bigint)
     returning id into v_id;
   else
     update g4a_private.grades set subject=p_data->>'subject',type=p_data->>'type',
       value=(p_data->>'value')::smallint,date=(p_data->>'date')::date,percent=nullif(p_data->>'percent','')::numeric
       where id=(p_data->>'id')::bigint and owner_id=uid returning id into v_id;
   end if;
   return jsonb_build_object('ok',v_id is not null);
 end if;
 return '{"ok":false,"message":"Neznana operacija."}'::jsonb;
end; $$;

     or (nullif(p_data->>'percent','') is not null
       and (coalesce(p_data->>'percent','') !~ '^[0-9]{1,3}([.][0-9]{1,2})?
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

         or (p_data->>'percent')::numeric > 100))
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
commit;
