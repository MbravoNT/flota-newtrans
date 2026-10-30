-- Ingreso a Taller con motivo 'Avería' deja el vehículo 'Bloqueado'.
-- La Salida del Taller libera a 'Operativo' tanto 'En mantención' como 'Bloqueado'.
-- Nunca modifica vehículos 'Inactivo'. Correr en Supabase → SQL Editor.

create or replace function public.taller_ingreso_estado_vehiculo()
 returns trigger language plpgsql security definer set search_path to 'public' as $$
begin
  if new.fecha_egreso is null then
    update vehiculos
       set estado = case when new.motivo_ingreso = 'Avería' then 'Bloqueado' else 'En mantención' end
     where patente = new.vehiculo_patente and estado is distinct from 'Inactivo';
  end if;
  return new;
end $$;

create or replace function public.taller_salida_estado_vehiculo()
 returns trigger language plpgsql security definer set search_path to 'public' as $$
begin
  update vehiculos set estado = 'Operativo'
   where patente = new.vehiculo_patente and estado in ('En mantención', 'Bloqueado');
  return new;
end $$;
