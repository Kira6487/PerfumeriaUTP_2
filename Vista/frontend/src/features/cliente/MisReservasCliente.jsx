import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import erpApi from '../../api/erpApi';

const tabs = [
  { key: '', label: 'Todas' },
  { key: 'O', label: 'Pendientes' },
  { key: 'A', label: 'Aprobadas' },
  { key: 'C', label: 'Entregadas' },
  { key: 'D', label: 'Canceladas' },
];

const statusLabel = {
  O: 'Pendiente de aprobacion',
  A: 'Aprobada',
  C: 'Entregada',
  D: 'Cancelada',
};

const statusStyle = {
  O: 'bg-amber-50 text-amber-800 border-amber-100',
  A: 'bg-pink-50 text-pink-700 border-pink-100',
  C: 'bg-rose-950 text-white border-rose-950',
  D: 'bg-rose-50 text-rose-700 border-rose-100',
};

const formatDate = (value) => {
  if (!value) return 'Sin fecha';
  return new Date(value).toLocaleDateString('es-PE', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};

const MisReservasCliente = () => {
  const [status, setStatus] = useState('');

  const { data: reservas = [], isLoading } = useQuery({
    queryKey: ['mis-reservas', status],
    queryFn: () => {
      const params = new URLSearchParams({ mine: '1' });
      if (status) params.set('status', status);
      return erpApi.get(`/reservas?${params.toString()}`).then((r) => r.data);
    },
    refetchInterval: 15000,
  });

  const { data: todasReservas = [] } = useQuery({
    queryKey: ['mis-reservas-resumen'],
    queryFn: () => erpApi.get('/reservas?mine=1').then((r) => r.data),
    refetchInterval: 15000,
  });

  const counts = useMemo(() => {
    const summary = { total: todasReservas.length, abiertas: 0, aprobadas: 0, cerradas: 0 };
    todasReservas.forEach((item) => {
      if (item.status === 'O') summary.abiertas += 1;
      if (item.status === 'A') summary.aprobadas += 1;
      if (item.status === 'C') summary.cerradas += 1;
    });
    return summary;
  }, [todasReservas]);

  return (
    <div className="client-page">
      <section className="rounded-[2rem] border border-pink-100 bg-white/80 p-6 shadow-sm backdrop-blur">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.28em] text-amber-500">Seguimiento</p>
            <h1 className="mt-2 text-3xl font-semibold text-rose-950">Mis reservas</h1>
            <p className="mt-2 max-w-xl text-sm leading-6 text-rose-500">
              Consulta el estado de tus solicitudes y revisa cuando una reserva fue aprobada o entregada.
            </p>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="client-mini-stat">
              <span>{counts.abiertas}</span>
              <p>Pendientes</p>
            </div>
            <div className="client-mini-stat">
              <span>{counts.aprobadas}</span>
              <p>Aprobadas</p>
            </div>
            <div className="client-mini-stat">
              <span>{counts.cerradas}</span>
              <p>Entregadas</p>
            </div>
          </div>
        </div>
      </section>

      <div className="mt-6 flex flex-wrap gap-2">
        {tabs.map((tab) => (
          <button
            key={tab.key || 'all'}
            onClick={() => setStatus(tab.key)}
            className={`rounded-full px-4 py-2 text-sm font-semibold transition-all ${
              status === tab.key
                ? 'bg-gradient-to-r from-rose-500 to-amber-400 text-white shadow-lg shadow-rose-200/70'
                : 'bg-white/80 text-rose-500 hover:bg-rose-50 hover:text-rose-800'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <section className="mt-5 overflow-hidden rounded-[2rem] border border-pink-100 bg-white/82 shadow-sm backdrop-blur">
        {isLoading ? (
          <div className="p-10 text-center text-sm text-rose-400">Cargando tus reservas...</div>
        ) : reservas.length === 0 ? (
          <div className="p-10 text-center">
            <p className="text-lg font-semibold text-rose-950">Aun no tienes reservas en este estado</p>
            <p className="mt-2 text-sm text-rose-400">Cuando reserves un producto, aparecera aqui.</p>
          </div>
        ) : (
          <div className="divide-y divide-rose-50">
            {reservas.map((reserva, index) => (
              <article
                key={reserva.id}
                className="reservation-row"
                style={{ animationDelay: `${Math.min(index * 50, 350)}ms` }}
              >
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.18em] text-amber-500">Reserva #{reserva.id}</p>
                  <h2 className="mt-1 text-lg font-semibold text-rose-950">{reserva.producto}</h2>
                  <p className="mt-2 text-sm text-rose-500">
                    Cantidad solicitada: <span className="font-semibold text-rose-800">{reserva.cantidad}</span>
                  </p>
                </div>

                <div className="flex flex-col items-start gap-2 sm:items-end">
                  <span className={`rounded-full border px-3 py-1 text-xs font-bold ${statusStyle[reserva.status]}`}>
                    {statusLabel[reserva.status] || reserva.status}
                  </span>
                  <p className="text-xs text-rose-400">Solicitada: {formatDate(reserva.fecha_creacion)}</p>
                  <p className="text-xs text-rose-400">Fecha deseada: {formatDate(reserva.planning_date)}</p>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>
    </div>
  );
};

export default MisReservasCliente;
