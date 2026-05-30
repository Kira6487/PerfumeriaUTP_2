import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const adminLinks = [
  { to: '/', label: 'Dashboard', icon: 'D' },
  { to: '/inventario', label: 'Inventario', icon: 'I' },
  { to: '/reservas', label: 'Reservas', icon: 'R' },
  { to: '/entregas', label: 'Entregas', icon: 'E' },
  { to: '/alertas', label: 'Alertas', icon: 'A' },
];

const clientLinks = [
  { to: '/', label: 'Catalogo', icon: 'C' },
  { to: '/mis-reservas', label: 'Mis reservas', icon: 'M' },
];

const Sidebar = () => {
  const { user, logout, isAdmin } = useAuth();
  const links = isAdmin ? adminLinks : clientLinks;

  return (
    <aside
      className={`w-56 min-h-screen border-r flex flex-col ${
        isAdmin
          ? 'bg-white border-gray-100'
          : 'bg-white/82 border-rose-100 shadow-[18px_0_50px_rgba(190,83,119,0.08)] backdrop-blur-xl'
      }`}
    >
      <div className={`px-5 py-6 border-b ${isAdmin ? 'border-gray-100' : 'border-rose-100'}`}>
        <div className="flex items-center gap-3">
          <div
            className={`w-9 h-9 rounded-xl flex items-center justify-center shadow-sm ${
              isAdmin
                ? 'bg-emerald-700'
                : 'bg-gradient-to-br from-rose-500 via-pink-500 to-amber-400'
            }`}
          >
            <span className="text-white font-bold text-sm">M</span>
          </div>
          <div>
            <p className={`text-sm font-semibold ${isAdmin ? 'text-gray-900' : 'text-rose-950'}`}>Marly</p>
            <p className={`text-xs ${isAdmin ? 'text-gray-400' : 'text-rose-400'}`}>Perfumeria</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 px-3 py-4 space-y-1">
        {links.map(({ to, label, icon }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-all duration-200 ${
                isAdmin
                  ? isActive
                    ? 'bg-emerald-50 text-emerald-700 font-medium'
                    : 'text-gray-600 hover:bg-gray-50'
                  : isActive
                    ? 'bg-gradient-to-r from-rose-500 to-amber-400 text-white font-semibold shadow-lg shadow-rose-200/60'
                    : 'text-rose-700 hover:bg-rose-50 hover:text-rose-950'
              }`
            }
          >
            <span
              className={`grid h-7 w-7 place-items-center rounded-lg text-xs font-bold ${
                isAdmin ? 'bg-gray-100' : 'bg-white/70'
              }`}
            >
              {icon}
            </span>
            {label}
          </NavLink>
        ))}
      </nav>

      <div className={`px-4 py-4 border-t ${isAdmin ? 'border-gray-100' : 'border-rose-100'}`}>
        <div className="mb-3">
          <p className={`text-xs font-medium truncate ${isAdmin ? 'text-gray-900' : 'text-rose-950'}`}>
            {user?.nombre}
          </p>
          <p className={`text-xs ${isAdmin ? 'text-gray-400' : 'text-rose-400'}`}>
            {isAdmin ? 'Administrador' : 'Cliente'}
          </p>
        </div>
        <button
          onClick={logout}
          className={`w-full text-left text-xs transition-colors ${
            isAdmin ? 'text-gray-400 hover:text-red-500' : 'text-rose-400 hover:text-rose-700'
          }`}
        >
          Cerrar sesion
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
