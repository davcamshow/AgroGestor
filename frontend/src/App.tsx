import { useState } from "react";
import { AuthPage } from "./views/Authpage";
import Layout from "./Layout";
import type { User } from "./types";

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState<User | null>(null);

  const handleLogin = () => {
    // Tu AuthPage solo llama onLogin() sin mandar user,
    // así que usamos un usuario demo para que el panel muestre nombre.
    setUser({ name: "Dr. Roberto", email: "demo@agrogestor.com" });
    setIsAuthenticated(true);
  };

  if (!isAuthenticated) {
    return <AuthPage onLogin={handleLogin} />;
  }

  return (
    <Layout
      onLogout={() => setIsAuthenticated(false)}
      user={user}
      onUpdateUser={(u) => setUser(u)}
    />
  );
}

export default App;