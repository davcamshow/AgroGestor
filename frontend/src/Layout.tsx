import React, { useState } from "react";
import {
  Leaf,
  Users,
  Beaker,
  Wheat,
  BarChart3,
  Settings,
  Bell,
  Search,
  FileText,
  CheckCircle,
  LogOut,
} from "lucide-react";

import type { User, Lote, Dieta, Insumo, ToastState } from "./types";

import DashboardView from "./views/DashboardView";
import LotesView from "./views/LotesView";
import FormulasView from "./views/FormulasView";
import InsumosView from "./views/InsumosView";
import ReportesView from "./views/ReportesView";
import ConfiguracionView from "./views/ConfiguracionView";

interface MainLayoutProps {
  onLogout: () => void;
  user: User | null;
  onUpdateUser: (user: User) => void;
}

const MainLayout: React.FC<MainLayoutProps> = ({ onLogout, user, onUpdateUser }) => {
  const [currentView, setCurrentView] = useState<string>("dashboard");
  const [toast, setToast] = useState<ToastState>({
    show: false,
    message: "",
    type: "success",
  });

  const showToast = (message: string, type: "success" | "error" = "success") => {
    setToast({ show: true, message, type });
    setTimeout(() => setToast({ show: false, message: "", type: "success" }), 3000);
  };

  // DATOS MOCK EXPANDIDOS
  const [lotes, setLotes] = useState<Lote[]>([
    { id: 1, nombre: "Engorda Lote A", cabezas: 45, peso_promedio: 350, etapa: "Engorda", estado: "Activo", id_dieta: 1 },
    { id: 2, nombre: "Vacas Secas B", cabezas: 120, peso_promedio: 450, etapa: "Mantenimiento", estado: "Activo", id_dieta: 2 },
    { id: 3, nombre: "Becerros Destete", cabezas: 30, peso_promedio: 180, etapa: "Destete", estado: "Activo", id_dieta: 3 },
    { id: 4, nombre: "Novillonas Reemplazo", cabezas: 60, peso_promedio: 280, etapa: "Destete", estado: "Activo", id_dieta: 4 },
    { id: 5, nombre: "Lote Finalización", cabezas: 85, peso_promedio: 480, etapa: "Engorda", estado: "Activo", id_dieta: 5 },
    { id: 6, nombre: "Vacas Lactancia", cabezas: 200, peso_promedio: 500, etapa: "Lactancia", estado: "Activo", id_dieta: 6 },
  ]);

  const [dietas, setDietas] = useState<Dieta[]>([
    { id: 1, nombre: "Engorda Fase 2", objetivo: "Engorda", fecha: "20 Feb", autor: user?.name, estado: "Activa", costo_kg: 4.5, ingredientes: [{ id_insumo: 1, porcentaje: 60 }, { id_insumo: 2, porcentaje: 40 }] },
    { id: 2, nombre: "Mantenimiento Secas", objetivo: "Mantenimiento", fecha: "18 Feb", autor: user?.name, estado: "Activa", costo_kg: 3.2, ingredientes: [{ id_insumo: 5, porcentaje: 80 }, { id_insumo: 4, porcentaje: 20 }] },
    { id: 3, nombre: "Iniciador Becerros", objetivo: "Destete", fecha: "15 Feb", autor: "Ing. López", estado: "En revisión", costo_kg: 6.8, ingredientes: [{ id_insumo: 1, porcentaje: 40 }, { id_insumo: 2, porcentaje: 40 }, { id_insumo: 3, porcentaje: 20 }] },
    { id: 4, nombre: "Desarrollo Novillonas", objetivo: "Destete", fecha: "10 Feb", autor: "Ing. López", estado: "Activa", costo_kg: 4.1, ingredientes: [{ id_insumo: 1, porcentaje: 50 }, { id_insumo: 6, porcentaje: 50 }] },
    { id: 5, nombre: "Finalización Intensiva", objetivo: "Engorda", fecha: "05 Feb", autor: user?.name, estado: "Activa", costo_kg: 5.2, ingredientes: [{ id_insumo: 1, porcentaje: 70 }, { id_insumo: 2, porcentaje: 20 }, { id_insumo: 4, porcentaje: 10 }] },
    { id: 6, nombre: "Lactancia Alta", objetivo: "Lactancia", fecha: "01 Feb", autor: user?.name, estado: "Activa", costo_kg: 5.8, ingredientes: [{ id_insumo: 1, porcentaje: 40 }, { id_insumo: 2, porcentaje: 30 }, { id_insumo: 7, porcentaje: 30 }] },
  ]);

  const [insumos, setInsumos] = useState<Insumo[]>([
    { id: 1, nombre: "Maíz Molido", cantidad_actual: 500, stock_minimo: 800, costo_kg: 5.5 },
    { id: 2, nombre: "Pasta de Soya 44%", cantidad_actual: 120, stock_minimo: 150, costo_kg: 12.0 },
    { id: 3, nombre: "Premezcla Mineral", cantidad_actual: 15, stock_minimo: 20, costo_kg: 45.0 },
    { id: 4, nombre: "Melaza de Caña", cantidad_actual: 1200, stock_minimo: 500, costo_kg: 2.8 },
    { id: 5, nombre: "Rastrojo de Maíz", cantidad_actual: 3000, stock_minimo: 1000, costo_kg: 1.5 },
    { id: 6, nombre: "Salvado de Trigo", cantidad_actual: 400, stock_minimo: 300, costo_kg: 4.2 },
    { id: 7, nombre: "Heno de Alfalfa", cantidad_actual: 1500, stock_minimo: 1000, costo_kg: 6.0 },
    { id: 8, nombre: "Urea Agrícola", cantidad_actual: 50, stock_minimo: 40, costo_kg: 15.5 },
  ]);

  const getInitials = (name?: string) => (name ? name.substring(0, 2).toUpperCase() : "DR");

  const renderView = () => {
    switch (currentView) {
      case "dashboard":
        return <DashboardView user={user} lotes={lotes} dietas={dietas} insumos={insumos} />;
      case "lotes":
        return <LotesView lotes={lotes} setLotes={setLotes} dietas={dietas} showToast={showToast} />;
      case "formulas":
        return <FormulasView dietas={dietas} setDietas={setDietas} insumos={insumos} showToast={showToast} user={user} />;
      case "insumos":
        return <InsumosView insumos={insumos} setInsumos={setInsumos} showToast={showToast} />;
      case "reportes":
        return <ReportesView lotes={lotes} dietas={dietas} insumos={insumos} />;
      case "configuracion":
        return <ConfiguracionView user={user} onUpdateUser={onUpdateUser} showToast={showToast} />;
      default:
        return <DashboardView user={user} lotes={lotes} dietas={dietas} insumos={insumos} />;
    }
  };

  return (
    <div className="flex h-screen bg-[#f8fafc] font-sans">
      {toast.show && (
        <div className="fixed bottom-4 right-4 bg-green-100 text-green-800 p-3 rounded-lg shadow-lg z-50 animate-in slide-in-from-bottom-5 font-medium flex items-center gap-2">
          <CheckCircle className="w-5 h-5" />
          {toast.message}
        </div>
      )}

      <aside className="w-64 bg-[#064e3b] text-white flex flex-col shadow-xl z-20">
        <div className="p-6 font-bold text-xl flex items-center gap-2 border-b border-emerald-800/50">
          <Leaf className="text-emerald-400" /> AgroGestor
        </div>

        <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
          <p className="px-3 text-xs font-bold text-emerald-400/50 uppercase tracking-wider mb-2">Principal</p>

          <button
            onClick={() => setCurrentView("dashboard")}
            className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors relative ${
              currentView === "dashboard" ? "bg-[#0d5942] text-white" : "text-emerald-100/70 hover:bg-emerald-800/50 hover:text-white"
            }`}
          >
            {currentView === "dashboard" && <div className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 bg-emerald-400 rounded-r-md"></div>}
            <BarChart3 className={`w-5 h-5 flex-shrink-0 ${currentView === "dashboard" ? "text-emerald-400 ml-1" : ""}`} />
            <span className="font-medium text-sm">Panel Principal</span>
          </button>

          <button
            onClick={() => setCurrentView("lotes")}
            className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors relative ${
              currentView === "lotes" ? "bg-[#0d5942] text-white" : "text-emerald-100/70 hover:bg-emerald-800/50 hover:text-white"
            }`}
          >
            {currentView === "lotes" && <div className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 bg-emerald-400 rounded-r-md"></div>}
            <Users className={`w-5 h-5 flex-shrink-0 ${currentView === "lotes" ? "text-emerald-400 ml-1" : ""}`} />
            <span className="font-medium text-sm">Lotes y Animales</span>
          </button>

          <button
            onClick={() => setCurrentView("formulas")}
            className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors relative ${
              currentView === "formulas" ? "bg-[#0d5942] text-white" : "text-emerald-100/70 hover:bg-emerald-800/50 hover:text-white"
            }`}
          >
            {currentView === "formulas" && <div className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 bg-emerald-400 rounded-r-md"></div>}
            <Beaker className={`w-5 h-5 flex-shrink-0 ${currentView === "formulas" ? "text-emerald-400 ml-1" : ""}`} />
            <span className="font-medium text-sm">Fórmulas y Dietas</span>
          </button>

          <button
            onClick={() => setCurrentView("insumos")}
            className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors relative ${
              currentView === "insumos" ? "bg-[#0d5942] text-white" : "text-emerald-100/70 hover:bg-emerald-800/50 hover:text-white"
            }`}
          >
            {currentView === "insumos" && <div className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 bg-emerald-400 rounded-r-md"></div>}
            <Wheat className={`w-5 h-5 flex-shrink-0 ${currentView === "insumos" ? "text-emerald-400 ml-1" : ""}`} />
            <span className="font-medium text-sm">Insumos e Inventario</span>
          </button>

          <button
            onClick={() => setCurrentView("reportes")}
            className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors relative ${
              currentView === "reportes" ? "bg-[#0d5942] text-white" : "text-emerald-100/70 hover:bg-emerald-800/50 hover:text-white"
            }`}
          >
            {currentView === "reportes" && <div className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 bg-emerald-400 rounded-r-md"></div>}
            <FileText className={`w-5 h-5 flex-shrink-0 ${currentView === "reportes" ? "text-emerald-400 ml-1" : ""}`} />
            <span className="font-medium text-sm">Reportes</span>
          </button>
        </nav>

        <div className="p-4 border-t border-emerald-800/50 space-y-2 bg-emerald-950/30">
          <button
            onClick={() => setCurrentView("configuracion")}
            className={`w-full flex items-center gap-3 p-3 rounded-lg transition-colors relative ${
              currentView === "configuracion" ? "bg-[#0d5942] text-white" : "text-emerald-100/70 hover:bg-emerald-800/50 hover:text-white"
            }`}
          >
            {currentView === "configuracion" && <div className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-1 bg-emerald-400 rounded-r-md"></div>}
            <Settings className={`w-5 h-5 flex-shrink-0 ${currentView === "configuracion" ? "text-emerald-400 ml-1" : ""}`} />
            <span className="font-medium text-sm">Configuración</span>
          </button>

          <button
            onClick={onLogout}
            className="w-full flex items-center gap-3 p-3 rounded-lg text-red-300 hover:bg-red-900/40 hover:text-red-200 transition-colors"
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium text-sm">Cerrar Sesión</span>
          </button>
        </div>
      </aside>

      <main className="flex-1 flex flex-col overflow-hidden relative">
        <header className="h-20 bg-white border-b border-gray-200 px-8 flex justify-between items-center z-10 shadow-sm">
          <div className="relative hidden md:block">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              className="pl-10 pr-4 py-2.5 w-80 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:bg-white focus:border-emerald-500 outline-none transition-all"
              placeholder="Buscar dietas, insumos..."
            />
          </div>

          <div className="flex items-center gap-4 sm:gap-6">
            <button className="relative text-gray-500 hover:text-emerald-600 transition-colors">
              <Bell className="w-5 h-5" />
              <span className="absolute -top-0.5 -right-0.5 w-2 h-2 bg-red-500 rounded-full border border-white"></span>
            </button>

            <div className="flex items-center gap-3 pl-4 border-l border-gray-200 cursor-pointer">
              <div className="w-10 h-10 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-700 font-bold border border-emerald-100">
                {getInitials(user?.name)}
              </div>
              <div className="hidden sm:block">
                <p className="text-sm font-bold text-gray-800 leading-tight">{user?.name || "Dr. Roberto"}</p>
                <p className="text-xs text-gray-500 font-medium">{user?.role || "Nutricionista"}</p>
              </div>
            </div>
          </div>
        </header>

        <div className="flex-1 overflow-y-auto p-4 md:p-8 bg-[#f8fafc]">{renderView()}</div>
      </main>
    </div>
  );
};

export default MainLayout;