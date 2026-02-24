import React, { useState } from "react";
import { PieChart, Users, Beaker, Wheat, Download, TrendingUp, Calendar, Activity } from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import type { Lote, Dieta, Insumo } from "../types";

interface ReportesViewProps {
  lotes: Lote[];
  dietas: Dieta[];
  insumos: Insumo[];
}

// Componente extraído para evitar re-renderizados innecesarios
interface TabButtonProps {
  id: string;
  label: string;
  icon: React.ElementType;
  isActive: boolean;
  onClick: (id: string) => void;
}

const TabButton: React.FC<TabButtonProps> = ({ id, label, icon: Icon, isActive, onClick }) => (
  <button 
    onClick={() => onClick(id)}
    className={`flex items-center gap-2 px-6 py-4 border-b-2 font-bold text-sm transition-all ${
      isActive 
        ? 'border-emerald-600 text-emerald-700 bg-emerald-50/50' 
        : 'border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-50/80 hover:border-gray-200'
    }`}
  >
    <Icon className="w-4 h-4" /> {label}
  </button>
);

const ReportesView: React.FC<ReportesViewProps> = ({ lotes, dietas, insumos }) => {
  const [activeTab, setActiveTab] = useState<string>('general');

  // Cálculos Globales
  const totalAnimales = lotes.reduce((acc, l) => acc + l.cabezas, 0);
  const valorInventario = insumos.reduce((acc, i) => acc + (i.cantidad_actual * i.costo_kg), 0);
  
  const costoDiarioTotal = lotes.reduce((total, lote) => {
    if (!lote.id_dieta) return total;
    const dieta = dietas.find(d => d.id === parseInt(lote.id_dieta as string));
    if (!dieta) return total;
    const consumoLote = lote.peso_promedio * 0.03 * lote.cabezas;
    return total + (consumoLote * dieta.costo_kg);
  }, 0);

  // Cálculos de Lotes
  const cabezasPorEtapa = lotes.reduce((acc: Record<string, number>, lote) => {
    acc[lote.etapa] = (acc[lote.etapa] || 0) + lote.cabezas;
    return acc;
  }, {});

  // Cálculos de Fórmulas
  const costoPromedioDietas = dietas.length > 0 ? (dietas.reduce((acc, d) => acc + d.costo_kg, 0) / dietas.length).toFixed(2) : '0.00';
  const insumosOrdenadosPorValor = [...insumos].sort((a, b) => (b.cantidad_actual * b.costo_kg) - (a.cantidad_actual * a.costo_kg));

  return (
    <div className="animate-in fade-in duration-300 max-w-7xl mx-auto">
      {/* CABECERA */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analítica y Reportes</h1>
          <p className="text-gray-500 text-sm mt-1">Visualiza el rendimiento y los costos de tu operación.</p>
        </div>
        <div className="flex items-center gap-3">
          <button className="flex items-center gap-2 bg-white border border-gray-200 text-gray-700 px-5 py-2.5 rounded-xl font-bold hover:bg-gray-50 shadow-sm transition-colors text-sm">
            <Calendar className="w-4 h-4" /> Este Mes
          </button>
          <button className="flex items-center gap-2 bg-emerald-600 text-white px-5 py-2.5 rounded-xl font-bold hover:bg-emerald-700 shadow-sm transition-colors text-sm">
            <Download className="w-4 h-4" /> Exportar
          </button>
        </div>
      </div>

     {/* TABS DE NAVEGACIÓN */}
      <div className="bg-white border-b border-gray-100 rounded-t-2xl flex overflow-x-auto hide-scrollbar shadow-sm mb-6">
        <TabButton id="general" label="Resumen General" icon={PieChart} isActive={activeTab === 'general'} onClick={setActiveTab} />
        <TabButton id="lotes" label="Reporte de Lotes" icon={Users} isActive={activeTab === 'lotes'} onClick={setActiveTab} />
        <TabButton id="formulas" label="Análisis de Dietas" icon={Beaker} isActive={activeTab === 'formulas'} onClick={setActiveTab} />
        <TabButton id="insumos" label="Valor de Inventario" icon={Wheat} isActive={activeTab === 'insumos'} onClick={setActiveTab} />
      </div>
      
      {/* CONTENEDOR DE PESTAÑAS */}
      <div className="space-y-6">
        
        {/* 1. RESUMEN GENERAL */}
        {activeTab === 'general' && (
          <div className="animate-in slide-in-from-bottom-2 duration-300">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                <p className="text-sm font-semibold text-gray-500 mb-2">Costo Estimado Diario</p>
                <p className="text-3xl font-black text-gray-900">${costoDiarioTotal.toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})}</p>
                <p className="text-xs text-emerald-600 font-bold mt-3 flex items-center gap-1"><TrendingUp className="w-3.5 h-3.5"/> Costo operativo actual</p>
              </div>
              <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                <p className="text-sm font-semibold text-gray-500 mb-2">Capital en Almacén</p>
                <p className="text-3xl font-black text-blue-700">${valorInventario.toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})}</p>
                <p className="text-xs text-gray-400 font-medium mt-3">Valor de insumos en stock</p>
              </div>
              <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                <p className="text-sm font-semibold text-gray-500 mb-2">Población Total</p>
                <p className="text-3xl font-black text-gray-900">{totalAnimales} <span className="text-sm font-bold text-gray-400">cbz</span></p>
                <p className="text-xs text-gray-400 font-medium mt-3">Distribuidos en {lotes.length} lotes</p>
              </div>
              <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
                <p className="text-sm font-semibold text-gray-500 mb-2">Fórmulas Activas</p>
                <p className="text-3xl font-black text-gray-900">{dietas.filter(d => d.estado === 'Activa').length}</p>
                <p className="text-xs text-gray-400 font-medium mt-3">Costo prom: ${costoPromedioDietas}/kg</p>
              </div>
            </div>

            <div className="bg-[#064e3b] rounded-2xl p-8 text-white shadow-xl overflow-hidden relative">
              <div className="absolute top-0 right-0 w-80 h-80 bg-emerald-500/20 rounded-full blur-3xl -mr-20 -mt-20 pointer-events-none"></div>
              <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-6">
                <div>
                  <h3 className="text-xl font-bold mb-3 flex items-center gap-2"><Activity className="w-6 h-6 text-emerald-400" /> Diagnóstico del Sistema</h3>
                  <p className="text-emerald-100/90 text-sm max-w-2xl leading-relaxed">
                    El sistema está operando con normalidad. Tienes {insumos.filter(i => i.cantidad_actual < i.stock_minimo).length} insumo(s) en estado crítico que requieren atención. 
                    Tus lotes consumen un estimado de <strong>${costoDiarioTotal.toLocaleString('en-US', {minimumFractionDigits: 2})} diarios</strong>.
                  </p>
                </div>
                <button onClick={() => setActiveTab('insumos')} className="bg-[#022c22] hover:bg-emerald-950 px-6 py-3 rounded-xl text-sm font-bold transition-colors whitespace-nowrap shadow-inner border border-emerald-800/50">
                  Ver detalle de inventario
                </button>
              </div>
            </div>
          </div>
        )}

        {/* 2. REPORTE DE LOTES */}
        {activeTab === 'lotes' && (
          <div className="animate-in slide-in-from-right-2 duration-300 grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-1">
              <div className="bg-white p-7 rounded-2xl border border-gray-100 shadow-sm h-full">
                <h3 className="font-bold text-gray-900 mb-6 text-lg">Distribución por Etapas</h3>
                <div className="space-y-6">
                  {Object.entries(cabezasPorEtapa).map(([etapa, cabezas], index) => {
                    const pct = ((cabezas as number / totalAnimales) * 100).toFixed(1);
                    const colorMap: Record<string, string> = { 'Engorda': 'bg-purple-500', 'Destete': 'bg-indigo-500', 'Mantenimiento': 'bg-teal-400', 'Lactancia': 'bg-pink-500' };
                    const bgClass = colorMap[etapa] || 'bg-gray-500';
                    return (
                      <div key={index}>
                        <div className="flex justify-between text-sm mb-2">
                          <span className={`font-bold ${colorMap[etapa] ? colorMap[etapa].replace('bg-', 'text-') : 'text-gray-700'}`}>{etapa}</span>
                          <span className="text-gray-500 font-medium">{cabezas as number} cbz ({pct}%)</span>
                        </div>
                        <div className="w-full h-2.5 bg-gray-100 rounded-full overflow-hidden">
                          <div className={`h-full ${bgClass} rounded-full`} style={{ width: `${pct}%` }}></div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
            <div className="lg:col-span-2 bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
              <div className="p-6 border-b border-gray-100"><h3 className="font-bold text-gray-900 text-lg">Desglose de Costos por Lote</h3></div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-gray-600">
                  <thead className="bg-gray-50/50 text-gray-500">
                    <tr>
                      <th className="px-6 py-4 font-semibold">Lote</th>
                      <th className="px-6 py-4 font-semibold">Población</th>
                      <th className="px-6 py-4 font-semibold text-right">Consumo Est. / Día</th>
                      <th className="px-6 py-4 font-semibold text-right">Costo / Día</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {lotes.map(lote => {
                      const dieta = dietas.find(d => d.id === parseInt(lote.id_dieta as string));
                      const consumoDiario = lote.peso_promedio * 0.03 * lote.cabezas;
                      const costoD = dieta ? consumoDiario * dieta.costo_kg : 0;
                      return (
                        <tr key={lote.id} className="hover:bg-gray-50 transition-colors">
                          <td className="px-6 py-5 font-bold text-gray-800">{lote.nombre}</td>
                          <td className="px-6 py-5 font-medium">{lote.cabezas} cbz</td>
                          <td className="px-6 py-5 text-right font-medium">{consumoDiario.toFixed(1)} kg</td>
                          <td className="px-6 py-5 font-black text-emerald-700 text-right">${costoD.toLocaleString('en-US', {minimumFractionDigits: 2})}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* 3. ANÁLISIS DE DIETAS */}
        {activeTab === 'formulas' && (
          <div className="animate-in slide-in-from-right-2 duration-300">
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
              <div className="p-6 border-b border-gray-100 flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
                <h3 className="font-bold text-gray-900 text-lg">Comparativa de Costos Nutricionales</h3>
                <span className="text-sm border border-emerald-200 bg-emerald-50/50 text-emerald-700 font-bold px-4 py-1.5 rounded-full">
                  Promedio: ${costoPromedioDietas}/kg
                </span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-gray-600">
                  <thead className="bg-gray-50/50 text-gray-500">
                    <tr>
                      <th className="px-6 py-4 font-semibold">Fórmula</th>
                      <th className="px-6 py-4 font-semibold">Objetivo</th>
                      <th className="px-6 py-4 font-semibold text-center">Ingredientes</th>
                      <th className="px-6 py-4 font-semibold text-right">Costo por kg</th>
                      <th className="px-6 py-4 font-semibold text-center">Variación vs Promedio</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {[...dietas].sort((a,b) => b.costo_kg - a.costo_kg).map(dieta => {
                      const variacion = dieta.costo_kg - parseFloat(costoPromedioDietas as string);
                      const isArriba = variacion > 0;
                      return (
                        <tr key={dieta.id} className="hover:bg-gray-50 transition-colors">
                          <td className="px-6 py-5 font-bold text-gray-800">{dieta.nombre}</td>
                          <td className="px-6 py-5"><StatusBadge status={dieta.objetivo} /></td>
                          <td className="px-6 py-5 text-center font-medium">{dieta.ingredientes.length} items</td>
                          <td className="px-6 py-5 font-black text-gray-900 text-right">${dieta.costo_kg.toFixed(2)}</td>
                          <td className="px-6 py-5 flex justify-center">
                            <span className={`inline-flex items-center justify-center min-w-[70px] text-xs font-bold px-3 py-1.5 rounded-xl ${isArriba ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'}`}>
                              {isArriba ? '+' : ''}{Math.abs(variacion).toFixed(2)}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* 4. VALOR DE INVENTARIO */}
        {activeTab === 'insumos' && (
          <div className="animate-in slide-in-from-right-2 duration-300 grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
              <div className="p-6 border-b border-gray-100"><h3 className="font-bold text-gray-900 text-lg">Valorización del Inventario (Top)</h3></div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-gray-600">
                  <thead className="bg-gray-50/50 text-gray-500">
                    <tr>
                      <th className="px-6 py-4 font-semibold">Insumo</th>
                      <th className="px-6 py-4 font-semibold text-right">Stock</th>
                      <th className="px-6 py-4 font-semibold text-right">Valor Total Invertido</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {insumosOrdenadosPorValor.slice(0, 7).map(insumo => {
                      const valor = insumo.cantidad_actual * insumo.costo_kg;
                      return (
                        <tr key={insumo.id} className="hover:bg-gray-50 transition-colors">
                          <td className="px-6 py-5 font-bold text-gray-800">{insumo.nombre}</td>
                          <td className="px-6 py-5 text-right font-medium">{insumo.cantidad_actual} kg</td>
                          <td className="px-6 py-5 font-black text-blue-600 text-right">${valor.toLocaleString('en-US', {minimumFractionDigits: 2})}</td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
            
            <div className="lg:col-span-1">
              <div className="bg-white p-7 rounded-2xl border border-gray-100 shadow-sm h-full flex flex-col">
                <h3 className="font-bold text-gray-900 text-lg mb-6">Capital Bloqueado</h3>
                <div className="flex-1 flex flex-col items-center justify-center">
                  
                  {/* Gráfica SVG de Dona idéntica al diseño */}
                  <div className="relative w-48 h-48 flex items-center justify-center mb-6">
                    <svg viewBox="0 0 36 36" className="w-full h-full transform -rotate-90">
                      {/* Círculo de fondo */}
                      <path
                        className="text-gray-100"
                        strokeWidth="5"
                        stroke="currentColor"
                        fill="none"
                        d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      />
                      {/* Círculo de progreso azul */}
                      <path
                        className="text-blue-500"
                        strokeWidth="5"
                        strokeDasharray="80, 100"
                        strokeLinecap="round"
                        stroke="currentColor"
                        fill="none"
                        d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      />
                    </svg>
                    <div className="absolute inset-0 flex flex-col items-center justify-center">
                      <p className="text-3xl font-black text-gray-900">${(valorInventario/1000).toFixed(1)}k</p>
                      <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mt-1">Total</p>
                    </div>
                  </div>

                  <p className="text-sm text-gray-500 text-center leading-relaxed px-4">
                    Distribución del valor total de materias primas en almacén.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ReportesView;