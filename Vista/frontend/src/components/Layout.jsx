import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import { useAuth } from '../context/AuthContext';

const Layout = () => {
  const { isAdmin } = useAuth();

  return (
    <div className={`flex min-h-screen ${isAdmin ? 'bg-gray-50' : 'client-shell'}`}>
      <Sidebar />
      <main className={`flex-1 overflow-auto ${isAdmin ? 'p-8' : 'p-5 lg:p-8'}`}>
        <Outlet />
      </main>
    </div>
  );
};

export default Layout;
