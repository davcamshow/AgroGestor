import { useState } from 'react';
import { AuthPage } from './views/Authpage';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const handleLogin = () => setIsAuthenticated(true);

  if (!isAuthenticated) {
    return <AuthPage onLogin={handleLogin} />;
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50">
      <h1 className="text-3xl font-bold text-emerald-900">Bienvenido al Dashboard</h1>
    </div>
  );
}

export default App;