import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import Login from '../features/auth/Login';
import Layout from '../components/Layout';
import Dashboard from '../features/dashboard/Dashboard';
import Inventario from '../features/inventario/Inventario';
import Reservas from '../features/reservas/Reservas';
import Entregas from '../features/entregas/Entregas';
import Alertas from '../features/alertas/Alertas';
import CatalogoCliente from '../features/cliente/CatalogoCliente';
import MisReservasCliente from '../features/cliente/MisReservasCliente';

const PrivateRoute = ({ children }) => {
  const { user } = useAuth();
  return user ? children : <Navigate to="/login" />;
};

const AdminRoute = ({ children }) => {
  const { isAdmin } = useAuth();
  return isAdmin ? children : <Navigate to="/" replace />;
};

const HomeRoute = () => {
  const { isAdmin } = useAuth();
  return isAdmin ? <Dashboard /> : <CatalogoCliente />;
};

const AppRouter = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={
          <PrivateRoute>
            <Layout />
          </PrivateRoute>
        }>
          <Route index element={<HomeRoute />} />
          <Route path="mis-reservas" element={<MisReservasCliente />} />
          <Route path="inventario" element={<AdminRoute><Inventario /></AdminRoute>} />
          <Route path="reservas" element={<AdminRoute><Reservas /></AdminRoute>} />
          <Route path="entregas" element={<AdminRoute><Entregas /></AdminRoute>} />
          <Route path="alertas" element={<AdminRoute><Alertas /></AdminRoute>} />
        </Route>
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
};

export default AppRouter;
