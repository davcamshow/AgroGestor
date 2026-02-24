import React, { useState } from "react";
import type { FormEvent } from "react";
import { Search, Plus, Filter, Edit, Trash2, X, Users, Info } from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import EmptyState from "../components/EmptyState";
import type { Lote, Dieta } from "../types";

interface LotesViewProps {
  lotes: Lote[];
  setLotes: React.Dispatch<React.SetStateAction<Lote[]>>;
  dietas: Dieta[];
  showToast: (msg: string, type?: 'success' | 'error') => void;
}

const LotesView: React.FC<LotesViewProps> = ({ lotes, setLotes, dietas, showToast }) => {
  // Filtros y Modal
  const [search, setSearch] = useState<string>('');
  const [filterEtapa, setFilterEtapa] = useState<string>('Todas');
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingLote, setEditingLote] = useState<Lote | null>(null);
  const [formData, setFormData] = useState<Omit<Lote, 'id' | 'estado'> & { id?: number, estado?: string }>({ 
    nombre: '', cabezas: 0, peso_promedio: 0, etapa: 'Engorda', id_dieta: '' 
  });

  // Filtrar lotes por nombre y etapa
  const filteredLotes = lotes.filter(l => 
    l.nombre.toLowerCase().includes(search.toLowerCase()) && (filterEtapa === 'Todas' || l.etapa === filterEtapa)
  );

  //  Gestión del modal y guardado
  const handleOpenModal = (lote: Lote | null = null) => {
    if (lote) { 
      setEditingLote(lote); 
      setFormData(lote); 
    } else { 
      setEditingLote(null); 
      setFormData({ nombre: '', cabezas: 0, peso_promedio: 0, etapa: 'Engorda', id_dieta: '' }); 
    }
    setIsModalOpen(true);
  };

  const handleSaveLote = (e: FormEvent) => {
    e.preventDefault();
    if (editingLote) {
      setLotes(lotes.map(l => l.id === editingLote.id ? { ...(formData as Lote), id: l.id, estado: l.estado } : l));
      showToast('Lote actualizado correctamente', 'success');
    } else {
      setLotes([...lotes, { ...(formData as Lote), id: Date.now(), estado: 'Activo' }]);
      showToast('Nuevo lote registrado', 'success');
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id: number) => {
    if(confirm('¿Seguro que deseas eliminar este lote?')) {
      setLotes(lotes.filter(l => l.id !== id)); showToast('Lote eliminado', 'error');
    }
  };

  // Estima costo diario (Peso * 3% consumo * Costo Dieta * Cabezas)
  const getCostoDiario = (lote: Lote) => {
    if (!lote.id_dieta) return '0.00';
    const dieta = dietas.find(d => d.id === parseInt(lote.id_dieta as string));
    if (!dieta) return '0.00';
    return (lote.peso_promedio * 0.03 * dieta.costo_kg * lote.cabezas).toFixed(2);
  };

  const inputClass = "w-full p-2.5 bg-white border border-gray-200 rounded-xl focus:bg-white focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all text-sm";

  return (
    <div className="animate-in fade-in duration-300 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Gestión de Lotes</h1>
          <p className="text-gray-500 text-sm mt-1">Controla tus grupos de animales, su etapa y dieta asignada.</p>
        </div>
        <button onClick={() => handleOpenModal()} className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-xl font-bold transition-colors shadow-sm text-sm">
          <Plus className="w-4 h-4" /> Registrar Lote
        </button>
      </div>

      {/*  Búsqueda y Filtro */}
      <div className="flex flex-col sm:flex-row gap-4 items-center justify-between mb-6">
        <div className="relative w-full sm:w-96">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input 
            type="text" 
            placeholder="Buscar lote..." 
            value={search} 
            onChange={(e) => setSearch(e.target.value)} 
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all shadow-sm font-medium text-gray-700" 
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <Filter className="w-4 h-4 text-gray-400 hidden sm:block" />
          <select 
            value={filterEtapa} 
            onChange={(e) => setFilterEtapa(e.target.value)} 
            className="w-full sm:w-auto py-2.5 px-4 bg-white border border-gray-200 rounded-xl text-sm focus:border-emerald-500 outline-none shadow-sm text-gray-700 font-bold cursor-pointer"
          >
            <option value="Todas">Todas las Etapas</option>
            <option value="Engorda">Engorda</option>
            <option value="Destete">Destete</option>
            <option value="Mantenimiento">Mantenimiento</option>
            <option value="Lactancia">Lactancia</option>
          </select>
        </div>
      </div>

      {/* TABLA DE LOTES */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600">
            <thead className="bg-gray-50/50 border-b border-gray-100 text-gray-500">
              <tr>
                <th className="px-6 py-4 font-semibold">Nombre del Lote</th>
                <th className="px-6 py-4 font-semibold">Cabezas</th>
                <th className="px-6 py-4 font-semibold">Promedio</th>
                <th className="px-6 py-4 font-semibold">Etapa</th>
                <th className="px-6 py-4 font-semibold">Dieta Asignada</th>
                <th className="px-6 py-4 font-semibold">Costo Est. / Día</th>
                <th className="px-6 py-4 font-semibold text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredLotes.length > 0 ? filteredLotes.map(lote => {
                const dieta = dietas.find(d => d.id === parseInt(lote.id_dieta as string));
                return (
                  <tr key={lote.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 font-bold text-gray-800">{lote.nombre}</td>
                    <td className="px-6 py-4">{lote.cabezas} cbz</td>
                    <td className="px-6 py-4">{lote.peso_promedio} kg</td>
                    <td className="px-6 py-4"><StatusBadge status={lote.etapa} /></td>
                    <td className="px-6 py-4">
                      {dieta ? (
                        <span className="text-emerald-700 font-bold bg-emerald-50 px-3 py-1.5 rounded-lg text-xs border border-emerald-100/50">
                          {dieta.nombre}
                        </span>
                      ) : (
                        <span className="text-gray-400 text-xs font-medium italic bg-gray-50 px-3 py-1.5 rounded-lg border border-gray-100">
                          Sin asignar
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 font-bold text-gray-900">${getCostoDiario(lote)}</td>
                    <td className="px-6 py-4 flex justify-end gap-1">
                      <button onClick={() => handleOpenModal(lote)} className="p-2 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Editar lote"><Edit className="w-4 h-4" /></button>
                      <button onClick={() => handleDelete(lote.id)} className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="Eliminar lote"><Trash2 className="w-4 h-4" /></button>
                    </td>
                  </tr>
                );
              }) : (
                <tr>
                  <td colSpan={7} className="p-12 text-center">
                    <EmptyState icon={<Users />} title="No se encontraron lotes" description="Ajusta tus filtros o registra un lote nuevo para comenzar." />
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* REGISTRO/EDICIÓN */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-gray-900/40 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center p-6 pb-4">
              <h3 className="text-xl font-bold text-gray-900">{editingLote ? 'Editar Lote' : 'Registrar Nuevo Lote'}</h3>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100 transition-colors"><X className="w-5 h-5"/></button>
            </div>
            <form onSubmit={handleSaveLote} className="p-6 pt-0 space-y-5">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Nombre del Lote</label>
                <input required type="text" value={formData.nombre} onChange={e => setFormData({...formData, nombre: e.target.value})} className={inputClass} placeholder="Ej. Lote Becerros A" />
              </div>
              
              <div className="grid grid-cols-2 gap-5">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Total Cabezas</label>
                  <input required type="number" min="1" value={formData.cabezas || ''} onChange={e => setFormData({...formData, cabezas: parseInt(e.target.value) || 0})} className={inputClass} placeholder="0" />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Peso Promedio (kg)</label>
                  <input required type="number" min="1" value={formData.peso_promedio || ''} onChange={e => setFormData({...formData, peso_promedio: parseInt(e.target.value) || 0})} className={inputClass} placeholder="0" />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-5">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Etapa Productiva</label>
                  <select value={formData.etapa} onChange={e => setFormData({...formData, etapa: e.target.value})} className={`${inputClass} cursor-pointer`}>
                    <option value="Engorda">Engorda</option>
                    <option value="Destete">Destete</option>
                    <option value="Mantenimiento">Mantenimiento</option>
                    <option value="Lactancia">Lactancia</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Asignar Dieta (Opcional)</label>
                  <select value={formData.id_dieta} onChange={e => setFormData({...formData, id_dieta: e.target.value})} className={`${inputClass} cursor-pointer`}>
                    <option value="">Sin dieta asignada</option>
                    {dietas.map(d=><option key={d.id} value={d.id}>{d.nombre} (${d.costo_kg}/kg)</option>)}
                  </select>
                </div>
              </div>

              <div className="bg-emerald-50/80 border border-emerald-100 p-4 rounded-xl flex gap-3 mt-2">
                <Info className="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5" />
                <p className="text-xs text-emerald-800 leading-relaxed font-medium">
                  Al asignar una dieta, AgroGestor estimará automáticamente el costo diario basado en un consumo promedio del 3% del peso vivo.
                </p>
              </div>

              <div className="pt-3 flex justify-end gap-3">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-5 py-2.5 text-gray-600 hover:bg-gray-100 rounded-xl font-bold transition-colors text-sm">
                  Cancelar
                </button>
                <button type="submit" className="px-5 py-2.5 bg-emerald-600 text-white rounded-xl font-bold hover:bg-emerald-700 transition-colors shadow-sm text-sm">
                  Guardar Lote
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default LotesView;