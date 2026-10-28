-- RG-57 Revisión de Vehículo (diaria) → alimenta pestaña Climatización
-- Correr en Supabase → SQL Editor. Solo agrega objetos; no modifica datos existentes.

alter table public.vehiculos add column if not exists clima_temp numeric(4,1);

create table public.revisiones_vehiculo (
  id            bigint generated always as identity primary key,
  patente       text not null,
  ciudad        text,
  fecha         date not null default current_date,
  km            integer check (km >= 0),
  conductor     text not null,
  rt_vigente    boolean,
  rt_vence      date,
  soap_vigente  boolean,
  gases_vigente boolean,
  gases_vence   date,
  checklist     jsonb not null default '{}'::jsonb,   -- {item: 'OK' | 'No OK'}
  clima_estado  text check (clima_estado in ('Operativo','Con falla')),  -- null = sin equipo
  temperatura   numeric(4,1),
  conforme      boolean not null,
  obs           text,
  usuario       text,
  user_id       uuid default auth.uid(),
  creado_en     timestamptz not null default now(),
  constraint obs_si_no_conforme check (conforme or coalesce(btrim(obs),'') <> ''),
  constraint temp_si_clima check (clima_estado is null or temperatura is not null)
);
create index on public.revisiones_vehiculo (patente, fecha desc);

alter table public.revisiones_vehiculo enable row level security;

create policy rev_select on public.revisiones_vehiculo for select to authenticated
  using (get_mi_rol() in ('Administrador','Gestor') or get_mi_ciudad() in (ciudad,'TODAS'));
create policy rev_insert on public.revisiones_vehiculo for insert to authenticated
  with check ((get_mi_rol() in ('Administrador','Gestor') or get_mi_ciudad() in (ciudad,'TODAS'))
              and user_id = auth.uid());
-- Sin políticas update/delete: registro de calidad inmutable.

-- La sección 4 del RG-57 actualiza el estado vigente de Climatización.
create or replace function public.trg_revision_a_clima() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update vehiculos set
    clima_equipo  = case when new.clima_estado is null then 'Sin equipo' else 'Con equipo' end,
    clima_estado  = new.clima_estado,
    clima_temp    = new.temperatura,
    clima_obs     = case when new.clima_estado = 'Con falla' then new.obs else clima_obs end,
    clima_fecha   = new.creado_en,
    clima_usuario = new.usuario || ' (RG-57)'
  where patente = new.patente;
  return new;
end $$;

create trigger trg_revision_a_clima after insert on public.revisiones_vehiculo
  for each row execute function public.trg_revision_a_clima();
