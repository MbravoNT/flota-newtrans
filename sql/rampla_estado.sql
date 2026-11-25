-- Sub-pestaña Taller > Rampla: estado de motor, equipo de clima y GPS por patente.
-- Correr en Supabase → SQL Editor.
create table if not exists public.rampla_estado (
  patente text primary key,
  marca   text,
  anio    int,
  motor   text check (motor in ('Operativo','Con falla','Sin equipo')),
  clima   text check (clima in ('Operativo','Con falla','Sin equipo')),
  gps     text check (gps   in ('Operativo','Con falla','Sin equipo')),
  obs     text,
  fecha   timestamptz,
  usuario text
);

insert into public.rampla_estado (patente, marca, anio) values
 ('JH 42 64','DORSEY',1996),('JJ 30 44','UTILITY',1996),('JJ 87 49','TRAILMOBILE',2005),
 ('PW VB 27','UTILITY',2006),('PW VB 28','UTILITY',2006),('PW ZJ 23','UTILITY',2018),
 ('PX DG 67','UTILITY',2018),('PX DJ 40','WABACH',2018),('PX FT 73','WABASAH',2018),
 ('PX GH 54','WABASAH',2018),('PX KT 64','UTILITY',2017),('PX KT 67','UTILITY',2017),
 ('PX PK 67','UTILITY',2018),('PX RW 55','WABASAH',2018)
on conflict (patente) do nothing;

alter table public.rampla_estado enable row level security;
create policy rampla_sel on public.rampla_estado for select to authenticated using (true);
create policy rampla_upd on public.rampla_estado for update to authenticated
  using (get_mi_rol() in ('Administrador','Gestor','Mecánico'))
  with check (get_mi_rol() in ('Administrador','Gestor','Mecánico'));
