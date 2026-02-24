import { useState } from 'react';
import { Leaf, ArrowRight } from 'lucide-react';
import { Input } from '../components/Input';

export const AuthPage = ({ onLogin }: { onLogin: () => void }) => {
  // ESTADO: 'true' muestra Login, 'false' muestra Registro
  const [isLogin, setIsLogin] = useState(true);

  return (
    <div className="flex min-h-screen w-full items-center justify-center p-4 lg:p-0">
      {/* Contenedor Principal con Sombra Premium */}
      <div className="relative flex h-full lg:h-[700px] w-full max-w-[1200px] overflow-hidden rounded-[40px] bg-white shadow-[0_20px_60px_-15px_rgba(0,0,0,0.1)]">
        
        {/* La clase 'translate-x' mueve este panel de izquierda a derecha según el estado isLogin */}
        <div 
          className={`absolute top-0 left-0 z-40 h-full w-1/2 bg-[#064e3b] p-16 text-white transition-transform duration-700 ease-[cubic-bezier(0.4,0,0.2,1)] flex flex-col justify-between ${
            isLogin ? 'translate-x-0' : 'translate-x-full'
          }`}
        >
          {/* Brillo decorativo sutil */}
          <div className="absolute inset-0 glass-glow pointer-events-none" />
          
          <div className="relative z-10 flex items-center gap-3">
            <div className="rounded-xl bg-white/10 p-2 backdrop-blur-md">
              <Leaf className="h-8 w-8 text-emerald-400" />
            </div>
            <span className="text-2xl font-bold tracking-tight">AgroGestor</span>
          </div>

          <div className="relative z-10 max-w-md">
            <h1 className="text-5xl font-extrabold leading-[1.1] tracking-tight">
              {isLogin ? 'Nutrición de precisión para tu ganadería.' : 'Únete a la red de expertos en nutrición animal.'}
            </h1>
            <p className="mt-8 text-lg text-emerald-100/70 leading-relaxed">
              {isLogin 
                ? 'Optimiza tus fórmulas, controla tus insumos y maximiza el rendimiento de tus lotes.' 
                : 'Accede a calculadoras avanzadas de raciones, gestión de inventarios e historiales clínicos.'}
            </p>
          </div>

          <p className="relative z-10 text-xs font-medium text-emerald-400/40 uppercase tracking-widest">
            © 2026 AgroGestor. Todos los derechos reservados.
          </p>
        </div>

        <div className="flex w-full lg:w-1/2 flex-col justify-center bg-white px-8 lg:px-20 text-left">
          <div className="w-full max-w-md mx-auto lg:mx-0">
            <h2 className="text-3xl font-bold text-slate-900">Registro de Profesional</h2>
            <p className="mt-2 text-slate-500 mb-8">Completa tu perfil profesional para configurar tu entorno.</p>
            
            <form className="space-y-4" onSubmit={(e) => { e.preventDefault(); onLogin(); }}>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Input label="Nombre completo *" placeholder="Ej. Dr. Roberto" required />
                <Input label="Teléfono / WhatsApp *" placeholder="10 dígitos" required />
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Input label="Perfil Profesional *" placeholder="Médico Veterinario" required />
                <Input label="Cédula (Opcional)" placeholder="No. Cédula" />
              </div>
              <Input label="Correo electrónico *" type="email" placeholder="tucorreo@ejemplo.com" required />
              <Input label="Contraseña *" type="password" placeholder="••••••••" required />
              
              <button type="submit" className="mt-6 flex w-full items-center justify-center gap-2 rounded-2xl bg-[#10b981] py-4 text-sm font-bold text-white shadow-xl shadow-emerald-100 transition-all hover:bg-emerald-600 active:scale-[0.98]">
                Completar Registro Profesional <ArrowRight className="h-5 w-5" />
              </button>
            </form>

            <button onClick={() => setIsLogin(true)} className="mt-8 w-full text-center text-sm font-bold text-emerald-600 hover:text-emerald-700">
              ¿Ya tienes cuenta? <span className="underline underline-offset-4 decoration-2">Inicia sesión aquí</span>
            </button>
          </div>
        </div>


        <div className="flex w-full lg:w-1/2 flex-col justify-center bg-white px-8 lg:px-20 text-left">
          <div className="w-full max-w-md mx-auto lg:mx-0">
            <h2 className="text-4xl font-extrabold text-slate-900 leading-tight">Bienvenido de nuevo</h2>
            <p className="mt-2 text-slate-500 mb-10">Ingresa tus credenciales para acceder a tu panel.</p>
            
            <form className="space-y-6" onSubmit={(e) => { e.preventDefault(); onLogin(); }}>
              <button type="button" className="flex w-full items-center justify-center gap-3 py-3 px-4 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-700 hover:bg-slate-50 transition-all shadow-sm">
                <img src="https://www.google.com/favicon.ico" className="w-4 h-4" alt="Google" />
                Continuar con Google
              </button>

              <div className="relative py-2">
                <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-slate-100"></div></div>
                <div className="relative flex justify-center text-xs uppercase"><span className="px-4 bg-white text-slate-400 font-medium tracking-widest">O usa tu correo</span></div>
              </div>

              <Input label="Correo electrónico *" type="email" placeholder="tucorreo@ejemplo.com" required />
              <div className="space-y-1">
                <div className="flex justify-between items-center mb-1 text-left">
                  <label className="text-xs font-bold text-slate-700 uppercase tracking-widest">Contraseña *</label>
                  <span className="text-xs font-bold text-emerald-600 cursor-pointer hover:underline">¿Olvidaste tu contraseña?</span>
                </div>
                <input 
                  type="password" 
                  placeholder="••••••••"
                  className="w-full rounded-2xl border border-slate-200 bg-slate-50 px-5 py-4 text-sm outline-none transition-all focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 shadow-sm"
                />
              </div>
              
              <button type="submit" className="mt-4 flex w-full items-center justify-center gap-2 rounded-2xl bg-[#10b981] py-4 text-sm font-bold text-white shadow-2xl shadow-emerald-200 transition-all hover:bg-emerald-600 active:scale-[0.98]">
                Ingresar al sistema <ArrowRight className="h-5 w-5" />
              </button>
            </form>

            <div className="mt-12 text-center lg:text-left">
              <p className="text-sm text-slate-500 font-medium">
                ¿Nuevo en AgroGestor? 
                <button onClick={() => setIsLogin(false)} className="ml-2 font-bold text-emerald-600 hover:text-emerald-700 underline underline-offset-4 decoration-2">
                  Crea tu perfil profesional
                </button>
              </p>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};