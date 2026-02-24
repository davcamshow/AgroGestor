import React, { useState } from "react";
import type { FormEvent } from "react";
import { LayoutGrid, List, Plus, ChevronRight, Eye, Edit, Trash2, X, Beaker } from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import EmptyState from "../components/EmptyState";
import type { Dieta, Insumo, User } from "../types";

interface FormulasViewProps {
  dietas: Dieta[];
  setDietas: React.Dispatch<React.SetStateAction<Dieta[]>>;
  insumos: Insumo[];
  showToast: (msg: string, type?: 'success' | 'error') => void;
  user: User | null;
}

const FormulasView: React.FC<FormulasViewProps> = ({ dietas, setDietas, insumos, showToast, user }) => {
  // Control de vista (tarjetas/tabla)
  const [viewMode, setViewMode] = useState<'cards' | 'table'>('cards');
  const [selectedDieta, setSelectedDieta] = useState<Dieta | null>(null);
  const [isFormModalOpen, setIsFormModalOpen] = useState<boolean>(false);
  const [formData, setFormData] = useState<Partial<Dieta>>({ id: undefined, nombre: '', objetivo: 'Engorda', estado: 'Activa', ingredientes: [] });

  // Abre el modal para crear (vacío) o editar (con datos)
  const handleOpenForm = (dieta: Dieta | null = null) => {
    setSelectedDieta(null); 
    if (dieta) setFormData(JSON.parse(JSON.stringify(dieta)));
    else setFormData({ id: undefined, nombre: '', objetivo: 'Engorda', estado: 'Activa', ingredientes: [{ id_insumo: '', porcentaje: '' }] });
    setIsFormModalOpen(true);
  };

  // Suma de porcentajes y costo total basado en insumos
  const getPorcentajeTotal = () => (formData.ingredientes || []).reduce((total, ing) => total + (parseFloat(ing.porcentaje as string) || 0), 0);
  const getCostoTotal = () => (formData.ingredientes || []).reduce((total, ing) => {
    const insumo = insumos.find(i => i.id === parseInt(ing.id_insumo as string));
    return total + (insumo ? insumo.costo_kg * ((parseFloat(ing.porcentaje as string)||0)/100) : 0);
  }, 0).toFixed(2);

  // Guardar fórmula (Crear o Actualizar)
  const handleSaveFormula = (e: FormEvent) => {
    e.preventDefault();
    if (getPorcentajeTotal() !== 100) { showToast('El porcentaje total debe ser exactamente 100%', 'error'); return; }
    const costoCalculado = parseFloat(getCostoTotal());
    if (formData.id) {
      setDietas(dietas.map(d => d.id === formData.id ? { ...(formData as Dieta), costo_kg: costoCalculado } : d));
    } else {
      setDietas([...dietas, { ...(formData as Dieta), id: Date.now(), fecha: new Date().toLocaleDateString('es-ES', { day: '2-digit', month: 'short', year: 'numeric' }), autor: user?.name || 'Dr. Roberto', costo_kg: costoCalculado }]);
    }
    setIsFormModalOpen(false); showToast('Fórmula guardada exitosamente', 'success');
  };

  const pctTotal = getPorcentajeTotal();
  const inputClass = "w-full p-2.5 bg-white border border-gray-200 rounded-xl focus:bg-white focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all text-sm";

  return (
    <div className="animate-in fade-in duration-300 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Fórmulas y Dietas</h1>
          <p className="text-gray-500 text-sm mt-1">Catálogo de raciones balanceadas y estimación de costos.</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="flex bg-gray-100/80 p-1 rounded-xl border border-gray-200/50 shadow-inner">
            <button onClick={() => setViewMode('cards')} className={`p-1.5 rounded-lg transition-all ${viewMode === 'cards' ? 'bg-white shadow-sm text-emerald-700' : 'text-gray-400 hover:text-gray-600'}`}>
              <LayoutGrid className="w-5 h-5" />
            </button>
            <button onClick={() => setViewMode('table')} className={`p-1.5 rounded-lg transition-all ${viewMode === 'table' ? 'bg-white shadow-sm text-emerald-700' : 'text-gray-400 hover:text-gray-600'}`}>
              <List className="w-5 h-5" />
            </button>
          </div>
          <button onClick={() => handleOpenForm()} className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-xl font-bold transition-colors shadow-sm text-sm">
            <Plus className="w-4 h-4"/> Crear Fórmula
          </button>
        </div>
      </div>

      {/* Vista de Tarjetas */}
      {viewMode === 'cards' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {dietas.map(dieta => (
            <div key={dieta.id} className="bg-white border border-gray-100 rounded-2xl p-6 shadow-sm hover:shadow-md transition-shadow flex flex-col justify-between">
              <div>
                <div className="flex justify-between items-start mb-4">
                  <div className="w-10 h-10 rounded-lg border border-emerald-100 bg-emerald-50 flex items-center justify-center text-emerald-500">
                    <Beaker className="w-5 h-5" />
                  </div>
                  <div className="flex flex-col items-end gap-1.5">
                    <StatusBadge status={dieta.estado} />
                    <StatusBadge status={dieta.objetivo} />
                  </div>
                </div>
                <h3 className="text-lg font-bold text-gray-900 mt-2 mb-1">{dieta.nombre}</h3>
                <p className="text-xs text-gray-500 leading-relaxed max-w-[220px]">Creada el {dieta.fecha} por {dieta.autor}</p>
              </div>
              <div className="flex justify-between items-center pt-5 mt-5 border-t border-gray-100">
                <div className="text-xs font-bold text-gray-500">Costo: <span className="text-emerald-600 text-lg font-black">${dieta.costo_kg}</span>/kg</div>
                <button onClick={() => setSelectedDieta(dieta)} className="text-emerald-600 hover:text-emerald-800 text-sm font-bold flex items-center gap-1 transition-colors">
                  Ver detalles <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
          {dietas.length === 0 && (
            <div className="col-span-full">
              <EmptyState icon={<Beaker/>} title="Sin Fórmulas" description="No tienes fórmulas registradas aún." actionText="Crear primera fórmula" onAction={() => handleOpenForm()} />
            </div>
          )}
        </div>
      //  Vista de Tabla 
      ) : (
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-600">
              <thead className="bg-gray-50/50 border-b border-gray-100 text-gray-500">
                <tr>
                  <th className="px-6 py-4 font-semibold">Nombre de Fórmula</th>
                  <th className="px-6 py-4 font-semibold">Objetivo</th>
                  <th className="px-6 py-4 font-semibold">Estado</th>
                  <th className="px-6 py-4 font-semibold">Ingredientes</th>
                  <th className="px-6 py-4 font-semibold">Costo / kg</th>
                  <th className="px-6 py-4 font-semibold text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {dietas.map(dieta => (
                  <tr key={dieta.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 font-bold text-gray-800">{dieta.nombre}</td>
                    <td className="px-6 py-4"><StatusBadge status={dieta.objetivo} /></td>
                    <td className="px-6 py-4"><StatusBadge status={dieta.estado} /></td>
                    <td className="px-6 py-4 font-medium">{dieta.ingredientes.length} items</td>
                    <td className="px-6 py-4 font-black text-emerald-700">${dieta.costo_kg}</td>
                    <td className="px-6 py-4 flex justify-end gap-2">
                      <button onClick={() => setSelectedDieta(dieta)} className="p-2 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Ver Detalles"><Eye className="w-4 h-4" /></button>
                      <button onClick={() => handleOpenForm(dieta)} className="p-2 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Editar"><Edit className="w-4 h-4" /></button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Detalles de visualización */}
      {selectedDieta && (
        <div className="fixed inset-0 bg-gray-900/40 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-xl overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="flex justify-between items-start p-6 pb-4">
              <div className="flex gap-4">
                <div className="w-12 h-12 bg-emerald-50 rounded-xl border border-emerald-100 flex items-center justify-center text-emerald-600">
                  <Beaker className="w-6 h-6"/>
                </div>
                <div>
                  <h3 className="text-xl font-black text-gray-900 leading-tight">{selectedDieta.nombre}</h3>
                  <p className="text-sm text-gray-500 mt-1">Autor: {selectedDieta.autor} | {selectedDieta.fecha}</p>
                </div>
              </div>
              <button onClick={() => setSelectedDieta(null)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100 transition-colors"><X className="w-5 h-5" /></button>
            </div>
            
            <div className="px-6 pb-6">
              <div className="grid grid-cols-2 gap-4 mb-8">
                <div className="bg-gray-50/80 border border-gray-100 rounded-2xl p-4">
                  <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-1">Costo Estimado</p>
                  <p className="text-2xl font-black text-emerald-600">${selectedDieta.costo_kg} <span className="text-sm text-gray-500 font-medium">/ kg</span></p>
                </div>
                <div className="bg-gray-50/80 border border-gray-100 rounded-2xl p-4">
                  <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-2">Objetivo</p>
                  <div><StatusBadge status={selectedDieta.objetivo} /></div>
                </div>
              </div>

              <h4 className="font-bold text-gray-900 mb-4 border-b border-gray-100 pb-2">Composición de la Dieta</h4>
              <table className="w-full text-left text-sm text-gray-600">
                <thead className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">
                  <tr>
                    <th className="pb-3">Insumo</th>
                    <th className="pb-3 text-right">Inclusión (%)</th>
                    <th className="pb-3 text-right">Costo Aportado</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {selectedDieta.ingredientes.map((ing, idx) => {
                    const insumoReal = insumos.find(i => i.id === parseInt(ing.id_insumo as string));
                    const nombre = insumoReal ? insumoReal.nombre : 'Insumo no encontrado';
                    const costoAportado = insumoReal ? (insumoReal.costo_kg * (parseFloat(ing.porcentaje as string) / 100)).toFixed(2) : '0.00';
                    return (
                      <tr key={idx}>
                        <td className="py-4 font-medium text-gray-900">{nombre}</td>
                        <td className="py-4 text-right font-medium">{ing.porcentaje}%</td>
                        <td className="py-4 text-right font-bold text-gray-700">${costoAportado}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            <div className="p-5 border-t border-gray-100 bg-gray-50/50 flex justify-end gap-3 rounded-b-3xl">
              <button onClick={() => setSelectedDieta(null)} className="px-5 py-2.5 text-gray-600 bg-white border border-gray-200 hover:bg-gray-100 rounded-xl font-bold transition-colors text-sm">Cerrar</button>
              <button onClick={() => handleOpenForm(selectedDieta)} className="px-5 py-2.5 bg-emerald-600 text-white rounded-xl font-bold hover:bg-emerald-700 transition-colors shadow-sm flex items-center gap-2 text-sm">
                <Edit className="w-4 h-4"/> Editar Fórmula
              </button>
            </div>
          </div>
        </div>
      )}

      {/*Formulario de Creación/Edición */}
      {isFormModalOpen && (
        <div className="fixed inset-0 bg-gray-900/40 flex items-center justify-center z-50 p-4 backdrop-blur-sm overflow-y-auto">
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-2xl overflow-hidden animate-in zoom-in-95 duration-200 flex flex-col my-auto max-h-[95vh]">
            <div className="flex justify-between items-center p-6 border-b border-gray-100 flex-shrink-0">
              <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                <Beaker className="w-5 h-5 text-emerald-600"/> 
                {formData.id ? 'Editar Fórmula' : 'Constructor de Fórmula'}
              </h3>
              <button type="button" onClick={() => setIsFormModalOpen(false)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100 transition-colors"><X className="w-5 h-5" /></button>
            </div>

            <form onSubmit={handleSaveFormula} className="flex-1 overflow-y-auto p-6">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 mb-8">
                <div className="sm:col-span-1">
                  <label className="block text-xs font-bold text-gray-700 mb-1.5">Nombre</label>
                  <input required type="text" value={formData.nombre} onChange={e=>setFormData({...formData, nombre:e.target.value})} className={inputClass} placeholder="Ej. Inicio 1" />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1.5">Objetivo</label>
                  <select value={formData.objetivo} onChange={e=>setFormData({...formData, objetivo:e.target.value})} className={`${inputClass} cursor-pointer`}>
                    <option value="Engorda">Engorda</option>
                    <option value="Destete">Destete</option>
                    <option value="Mantenimiento">Mantenimiento</option>
                    <option value="Lactancia">Lactancia</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1.5">Estado</label>
                  <select value={formData.estado} onChange={e=>setFormData({...formData, estado:e.target.value})} className={`${inputClass} cursor-pointer`}>
                    <option value="Activa">Activa</option>
                    <option value="En revisión">En revisión</option>
                    <option value="Archivada">Archivada</option>
                  </select>
                </div>
              </div>

              <div className="mb-4 flex items-center justify-between border-b border-gray-100 pb-2">
                <h4 className="text-sm font-bold text-gray-900">Ingredientes y Porcentajes</h4>
                <button type="button" onClick={() => setFormData({...formData, ingredientes: [...(formData.ingredientes||[]), {id_insumo: '', porcentaje: ''}]})} className="text-xs font-bold text-emerald-600 flex items-center gap-1 hover:bg-emerald-50 px-3 py-1.5 rounded-lg transition-colors">
                  <Plus className="w-3 h-3" /> Añadir
                </button>
              </div>

              <div className="space-y-3 mb-6">
                {(formData.ingredientes || []).map((ing, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <div className="flex-1">
                      <select required value={ing.id_insumo} onChange={e => { const newI = [...(formData.ingredientes||[])]; newI[i].id_insumo = e.target.value; setFormData({...formData, ingredientes: newI})}} className={`${inputClass} cursor-pointer`}>
                        <option value="">Seleccionar insumo...</option>
                        {insumos.map(ins=><option key={ins.id} value={ins.id}>{ins.nombre} (${ins.costo_kg}/kg)</option>)}
                      </select>
                    </div>
                    <div className="relative w-28">
                      <input required type="number" step="0.01" min="0.01" max="100" value={ing.porcentaje} onChange={e => { const newI = [...(formData.ingredientes||[])]; newI[i].porcentaje = e.target.value; setFormData({...formData, ingredientes: newI})}} className={`${inputClass} pr-8 text-right font-medium`} placeholder="0" />
                      <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 font-bold text-sm">%</span>
                    </div>
                    <button type="button" onClick={() => { const newI = [...(formData.ingredientes||[])]; newI.splice(i, 1); setFormData({...formData, ingredientes: newI}); }} className="p-2.5 text-red-400 hover:bg-red-50 hover:text-red-600 rounded-xl transition-colors flex-shrink-0" title="Eliminar">
                      <Trash2 className="w-5 h-5" />
                    </button>
                  </div>
                ))}
                {(!formData.ingredientes || formData.ingredientes.length === 0) && (
                  <div className="text-center p-8 border-2 border-dashed border-gray-200 rounded-2xl text-gray-500 text-sm font-medium">
                    Añade insumos de tu inventario para componer la fórmula.
                  </div>
                )}
              </div>
            </form>

            <div className="bg-gray-50/80 border-t border-gray-100 p-6 flex flex-col sm:flex-row justify-between items-center gap-6 rounded-b-3xl flex-shrink-0">
              <div className="flex gap-8 w-full sm:w-auto">
                <div>
                  <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-1">Total Mezcla</p>
                  <div className="flex items-baseline gap-2">
                    <span className={`text-2xl font-black ${pctTotal === 100 ? 'text-emerald-600' : 'text-red-500'}`}>{pctTotal}%</span>
                    {pctTotal !== 100 && <span className="text-xs font-medium text-red-400">(Debe ser 100%)</span>}
                  </div>
                </div>
                <div>
                  <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-1">Costo Estimado</p>
                  <p className="text-2xl font-black text-gray-900">${getCostoTotal()} <span className="text-sm font-medium text-gray-500">/ kg</span></p>
                </div>
              </div>
              
              <div className="flex justify-end gap-3 w-full sm:w-auto">
                <button type="button" onClick={() => setIsFormModalOpen(false)} className="px-5 py-2.5 text-gray-600 bg-white border border-gray-200 hover:bg-gray-50 rounded-xl font-bold transition-colors text-sm w-full sm:w-auto">
                  Cancelar
                </button>
                <button type="button" onClick={handleSaveFormula} className={`px-5 py-2.5 rounded-xl font-bold text-white transition-colors text-sm w-full sm:w-auto shadow-sm ${pctTotal === 100 && (formData.ingredientes?.length||0) > 0 ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-gray-400 cursor-not-allowed'}`}>
                  Guardar Fórmula
                </button>
              </div>
            </div>

          </div>
        </div>
      )}
    </div>
  );
};

export default FormulasView;