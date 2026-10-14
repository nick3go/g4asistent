-- G4Asistent: razred uporabnika. Obstoječi računi dobijo privzeto G4A.
-- Ne spreminja podatkov Timeline.
begin;
alter table g4a_private.users add column if not exists class_name text not null default 'G4A';
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
commit;
