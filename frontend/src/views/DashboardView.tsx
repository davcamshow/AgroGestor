import React from "react";
import { Plus, AlertTriangle, ChevronRight, Book } from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import type { User, Lote, Dieta, Insumo } from "../types";

interface DashboardViewProps {
  user: User | null;
  lotes: Lote[];
  dietas: Dieta[];
  insumos: Insumo[];
}

const DashboardView: React.FC<DashboardViewProps> = ({ user, lotes, dietas, insumos }) => {
  const totalAnimales = lotes.reduce((acc, lote) => acc + lote.cabezas, 0);
  const dietasActivas = dietas.filter(d => d.estado === 'Activa').length;
  
  // Costo diario total para el dashboard
  const costoDiarioTotal = lotes.reduce((total, lote) => {
    if (!lote.id_dieta) return total;
    const dieta = dietas.find(d => d.id === parseInt(lote.id_dieta as string));
    if (!dieta) return total;
    const consumoLote = lote.peso_promedio * 0.03 * lote.cabezas;
    return total + (consumoLote * dieta.costo_kg);
  }, 0);

  const costoPromedio = totalAnimales > 0 ? (costoDiarioTotal / totalAnimales).toFixed(2) : '0.00';
  const insumosCriticosY_bajos = insumos.filter(i => i.cantidad_actual <= i.stock_minimo * 1.2).sort((a, b) => a.cantidad_actual - b.cantidad_actual);

  return (
    <div className="animate-in fade-in duration-300 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Bienvenido{user?.name ? `, ${user.name}` : ' a AgroGestor'}</h1>
          <p className="text-gray-500 text-sm mt-1">Resumen general de tus formulaciones e inventario.</p>
        </div>
        <button className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-lg font-medium transition-colors shadow-sm text-sm">
          <Plus className="w-4 h-4" /> Nueva Formulación
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col justify-between">
          <h3 className="text-gray-500 text-sm font-medium mb-3">Total de Animales</h3>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-bold text-gray-900">{totalAnimales}</span>
          </div>
          <div className="mt-5">
            <span className="inline-block px-3 py-1 rounded-full text-xs font-bold bg-blue-50 text-blue-500 tracking-wide">
              Distribuidos en {lotes.length} lotes
            </span>
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col justify-between">
          <h3 className="text-gray-500 text-sm font-medium mb-3">Dietas Activas</h3>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-bold text-gray-900">{dietasActivas}</span>
          </div>
          <div className="mt-5">
            <span className="inline-block px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-500 tracking-wide">
              {dietas.length - dietasActivas} por revisar
            </span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex flex-col justify-between">
          <h3 className="text-gray-500 text-sm font-medium mb-3">Costo Promedio / Día / Cabeza</h3>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-bold text-gray-900">${costoPromedio}</span>
          </div>
          <div className="mt-5">
            <span className="inline-block px-3 py-1 rounded-full text-xs font-bold bg-purple-50 text-purple-500 tracking-wide">
              -2% vs mes anterior
            </span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden flex flex-col">
          <div className="flex justify-between items-center p-6 pb-2">
            <h2 className="text-lg font-bold text-gray-900">Dietas y Formulaciones Recientes</h2>
            <button className="text-sm text-emerald-600 hover:text-emerald-800 font-medium flex items-center gap-1 transition-colors">
              Ver todas <ChevronRight className="w-4 h-4" />
            </button>
          </div>
          <div className="p-3">
            {dietas.slice(0, 4).map((dieta, index) => (
              <div key={index} className="p-4 flex items-center justify-between hover:bg-gray-50 rounded-xl transition-colors cursor-pointer mb-1">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-lg border border-emerald-100 bg-emerald-50 flex items-center justify-center text-emerald-500">
                    <Book className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-medium text-gray-900 text-sm">{dieta.nombre}</h4>
                    <p className="text-xs text-gray-500 mt-0.5">Actualizado el {dieta.fecha || 'Recientemente'} por {dieta.autor}</p>
                  </div>
                </div>
                <StatusBadge status={dieta.estado} />
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 p-6 pb-2">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
            <h2 className="text-lg font-bold text-gray-900">Alertas de Insumos</h2>
          </div>
          <div className="p-6 pt-3 flex-1 flex flex-col">
            <p className="text-sm text-gray-500 mb-6 leading-relaxed">
              Los siguientes ingredientes están por debajo del stock mínimo recomendado.
            </p>
            <div className="space-y-3 mb-6">
              {insumosCriticosY_bajos.slice(0, 4).map((item, idx) => {
                const esCritico = item.cantidad_actual < item.stock_minimo;
                return (
                  <div key={idx} className={`p-4 rounded-xl border ${esCritico ? 'bg-red-50/40 border-red-100' : 'bg-orange-50/40 border-orange-100'}`}>
                    <div className="flex justify-between items-center mb-2">
                      <span className="font-bold text-sm text-gray-900">{item.nombre}</span>
                      <span className={`text-[10px] uppercase tracking-wider font-bold px-2 py-0.5 rounded-md ${esCritico ? 'bg-red-100 text-red-600' : 'bg-amber-100 text-amber-600'}`}>
                        {esCritico ? 'Crítico' : 'Bajo'}
                      </span>
                    </div>
                    <div className="text-xs text-gray-600 flex items-center gap-1">
                      <span>Actual: <strong className={esCritico ? 'text-red-600 font-bold' : 'text-gray-900 font-bold'}>{item.cantidad_actual} kg</strong></span>
                      <span className="text-gray-300 px-1">Mínimo: {item.stock_minimo}</span>
                    </div>
                  </div>
                );
              })}
            </div>
            <button className="w-full mt-auto py-2.5 border border-gray-200 rounded-lg text-sm font-semibold text-gray-600 hover:bg-gray-50 transition-colors">
              Generar Orden de Compra
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardView;