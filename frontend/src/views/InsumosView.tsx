import React, { useState } from "react";
import type { FormEvent } from "react";
import {
  Search, Filter, PackagePlus, Edit, Trash2, X,
  Wheat, DollarSign, AlertTriangle, CheckCircle,
  ArrowUpRight, ArrowDownRight
} from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import EmptyState from "../components/EmptyState";
import type { Insumo } from "../types";

interface InsumosViewProps {
  insumos: Insumo[];
  setInsumos: React.Dispatch<React.SetStateAction<Insumo[]>>;
  showToast: (msg: string, type?: 'success' | 'error') => void;
}

const InsumosView: React.FC<InsumosViewProps> = ({ insumos, setInsumos, showToast }) => {
  const [search, setSearch] = useState<string>('');
  const [filterStatus, setFilterStatus] = useState<string>('Todos los Estados');
  
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [editingInsumo, setEditingInsumo] = useState<Insumo | null>(null);
  const [formData, setFormData] = useState<Omit<Insumo, 'id'> & { id?: number }>({ nombre: '', cantidad_actual: 0, stock_minimo: 0, costo_kg: 0 });

  const [isAdjustOpen, setAdjustOpen] = useState<boolean>(false);
  const [currInsumo, setCurrInsumo] = useState<Insumo | null>(null);
  const [adjData, setAdjustData] = useState<{tipo: string, cant: string}>({tipo: 'entrada', cant: ''});

  const valorTotalInventario = insumos.reduce((total, item) => total + (item.cantidad_actual * item.costo_kg), 0);
  const insumosCriticos = insumos.filter(i => i.cantidad_actual < i.stock_minimo).length;

  const filteredInsumos = insumos.filter(insumo => {
    const matchesSearch = insumo.nombre.toLowerCase().includes(search.toLowerCase());
    const isCritico = insumo.cantidad_actual < insumo.stock_minimo;
    const matchesFilter = filterStatus === 'Todos los Estados' || 
                          (filterStatus === 'Solo Críticos' && isCritico) || 
                          (filterStatus === 'Adecuados' && !isCritico);
    return matchesSearch && matchesFilter;
  });

  const handleOpenModal = (insumo: Insumo | null = null) => {
    if (insumo) {
      setEditingInsumo(insumo);
      setFormData(insumo);
    } else {
      setEditingInsumo(null);
      setFormData({ nombre: '', cantidad_actual: 0, stock_minimo: 0, costo_kg: 0 });
    }
    setIsModalOpen(true);
  };

  const handleSaveInsumo = (e: FormEvent) => {
    e.preventDefault();
    if (editingInsumo) {
      setInsumos(insumos.map(i => i.id === editingInsumo.id ? { ...(formData as Insumo), id: i.id } : i));
      showToast('Insumo actualizado correctamente', 'success');
    } else {
      setInsumos([...insumos, { ...(formData as Insumo), id: Date.now() }]);
      showToast('Nuevo insumo registrado', 'success');
    }
    setIsModalOpen(false);
  };

  const handleDelete = (id: number) => {
    if(confirm('¿Seguro que deseas eliminar este insumo? Las fórmulas que lo usen podrían verse afectadas.')) {
      setInsumos(insumos.filter(i => i.id !== id));
      showToast('Insumo eliminado del inventario', 'error');
    }
  };

  const handleOpenAdjust = (insumo: Insumo) => {
    setCurrInsumo(insumo);
    setAdjustData({ tipo: 'entrada', cant: '' });
    setAdjustOpen(true);
  };

  const handleAdjust = (e: FormEvent) => {
    e.preventDefault();
    if (!currInsumo) return;
    const cantidadAjuste = parseFloat(adjData.cant);
    if (!cantidadAjuste || cantidadAjuste <= 0) return;

    let nCant = currInsumo.cantidad_actual;
    if (adjData.tipo === 'entrada') {
      nCant += cantidadAjuste;
    } else {
      if (cantidadAjuste > nCant) {
        showToast('La salida no puede ser mayor al stock actual', 'error');
        return;
      }
      nCant -= cantidadAjuste;
    }

    setInsumos(insumos.map(i => i.id === currInsumo.id ? {...i, cantidad_actual: nCant} : i));
    setAdjustOpen(false); 
    showToast(`Stock actualizado: ${adjData.tipo === 'entrada' ? '+' : '-'}${cantidadAjuste} kg`, 'success');
  }

  const inputClass = "w-full p-2.5 bg-white border border-gray-200 rounded-xl focus:bg-white focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all text-sm";

  return (
    <div className="animate-in fade-in duration-300 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Insumos e Inventario</h1>
          <p className="text-gray-500 text-sm mt-1">Control de materia prima, costos y existencias.</p>
        </div>
        <button onClick={() => handleOpenModal()} className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-xl font-bold transition-colors shadow-sm text-sm">
          <PackagePlus className="w-4 h-4" /> Registrar Insumo
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-5">
          <div className="w-14 h-14 bg-emerald-50 rounded-full flex items-center justify-center text-emerald-600 border border-emerald-100/50">
            <Wheat className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 mb-1">Total Insumos</p>
            <p className="text-3xl font-black text-gray-900">{insumos.length}</p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-5">
          <div className="w-14 h-14 bg-blue-50 rounded-full flex items-center justify-center text-blue-600 border border-blue-100/50">
            <DollarSign className="w-6 h-6" />
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 mb-1">Valor del Inventario</p>
            <p className="text-3xl font-black text-gray-900">${valorTotalInventario.toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})}</p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-5">
          <div className={`w-14 h-14 rounded-full flex items-center justify-center border ${insumosCriticos > 0 ? 'bg-red-50 text-red-600 border-red-100/50' : 'bg-green-50 text-green-600 border-green-100/50'}`}>
            {insumosCriticos > 0 ? <AlertTriangle className="w-6 h-6" /> : <CheckCircle className="w-6 h-6" />}
          </div>
          <div>
            <p className="text-sm font-medium text-gray-500 mb-1">Alertas Críticas</p>
            <p className={`text-3xl font-black ${insumosCriticos > 0 ? 'text-red-600' : 'text-gray-900'}`}>{insumosCriticos} <span className="text-lg font-bold">insumos</span></p>
          </div>
        </div>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 items-center justify-between mb-6">
        <div className="relative w-full sm:w-96">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input 
            type="text" 
            placeholder="Buscar ingrediente..." 
            value={search} 
            onChange={(e) => setSearch(e.target.value)} 
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all shadow-sm font-medium text-gray-700" 
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto relative">
          <Filter className="w-4 h-4 text-gray-400 absolute left-3 pointer-events-none hidden sm:block" />
          <select 
            value={filterStatus} 
            onChange={(e) => setFilterStatus(e.target.value)} 
            className="w-full sm:w-auto py-2.5 sm:pl-10 px-4 bg-white border border-gray-200 rounded-xl text-sm focus:border-emerald-500 outline-none shadow-sm text-gray-700 font-bold cursor-pointer"
          >
            <option value="Todos los Estados">Todos los Estados</option>
            <option value="Solo Críticos">Solo Críticos</option>
            <option value="Adecuados">Adecuados</option>
          </select>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600">
            <thead className="bg-gray-50/50 border-b border-gray-100 text-gray-500">
              <tr>
                <th className="px-6 py-4 font-semibold">Ingrediente</th>
                <th className="px-6 py-4 font-semibold">Stock Actual</th>
                <th className="px-6 py-4 font-semibold">Stock Mín.</th>
                <th className="px-6 py-4 font-semibold">Costo (kg)</th>
                <th className="px-6 py-4 font-semibold">Valor Total</th>
                <th className="px-6 py-4 font-semibold">Estado</th>
                <th className="px-6 py-4 font-semibold text-right">Acciones</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredInsumos.length > 0 ? filteredInsumos.map(insumo => {
                const isCritico = insumo.cantidad_actual < insumo.stock_minimo;
                const porcentaje = Math.min((insumo.cantidad_actual / (insumo.stock_minimo * 2)) * 100, 100);
                const valorFila = insumo.cantidad_actual * insumo.costo_kg;
                
                return (
                  <tr key={insumo.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 font-bold text-gray-800">{insumo.nombre}</td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col gap-1.5 w-24">
                        <span className={`font-black ${isCritico ? 'text-red-600' : 'text-gray-900'}`}>{insumo.cantidad_actual} kg</span>
                        <div className="w-full h-1.5 bg-gray-200 rounded-full overflow-hidden">
                          <div className={`h-full rounded-full ${isCritico ? 'bg-red-500' : 'bg-emerald-500'}`} style={{ width: `${porcentaje}%` }}></div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-500">{insumo.stock_minimo} kg</td>
                    <td className="px-6 py-4 font-medium text-gray-700">${insumo.costo_kg}</td>
                    <td className="px-6 py-4 font-bold text-gray-700">${valorFila.toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})}</td>
                    <td className="px-6 py-4"><StatusBadge status={isCritico ? 'Crítico' : 'Adecuado'} /></td>
                    <td className="px-6 py-4 flex items-center justify-end gap-3">
                      <button onClick={() => handleOpenAdjust(insumo)} className="font-bold text-blue-600 hover:text-blue-800 transition-colors mr-1" title="Ajustar Stock">
                        Ajustar
                      </button>
                      <button onClick={() => handleOpenModal(insumo)} className="p-1.5 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors" title="Editar"><Edit className="w-4 h-4" /></button>
                      <button onClick={() => handleDelete(insumo.id)} className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors" title="Eliminar"><Trash2 className="w-4 h-4" /></button>
                    </td>
                  </tr>
                );
              }) : (
                <tr><td colSpan={7} className="p-12 text-center"><EmptyState icon={<Wheat />} title="Inventario vacío o sin resultados" description="No hay insumos que coincidan con tu búsqueda." /></td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-gray-900/40 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="flex justify-between items-center p-6 pb-4">
              <h3 className="text-xl font-bold text-gray-900">{editingInsumo ? 'Editar Insumo' : 'Registrar Nuevo Insumo'}</h3>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100 transition-colors"><X className="w-5 h-5" /></button>
            </div>
            <form onSubmit={handleSaveInsumo} className="p-6 pt-0 space-y-5">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Nombre del Ingrediente</label>
                <input required type="text" value={formData.nombre} onChange={e => setFormData({...formData, nombre: e.target.value})} className={inputClass} placeholder="Ej. Maíz Molido" />
              </div>
              <div className="grid grid-cols-2 gap-5">
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Stock Actual (kg)</label>
                  <input required type="number" step="0.01" min="0" value={formData.cantidad_actual === 0 ? '' : formData.cantidad_actual} onChange={e => setFormData({...formData, cantidad_actual: parseFloat(e.target.value) || 0})} className={inputClass} placeholder="0" />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-1.5">Stock Mínimo (kg)</label>
                  <input required type="number" step="0.01" min="0" value={formData.stock_minimo === 0 ? '' : formData.stock_minimo} onChange={e => setFormData({...formData, stock_minimo: parseFloat(e.target.value) || 0})} className={inputClass} placeholder="0" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-1.5">Costo por Kg ($)</label>
                <input required type="number" step="0.01" min="0" value={formData.costo_kg === 0 ? '' : formData.costo_kg} onChange={e => setFormData({...formData, costo_kg: parseFloat(e.target.value) || 0})} className={inputClass} placeholder="0.00" />
              </div>
              <div className="pt-3 flex justify-end gap-3 border-t border-gray-100 mt-2">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-5 py-2.5 text-gray-600 hover:bg-gray-100 rounded-xl font-bold transition-colors text-sm">Cancelar</button>
                <button type="submit" className="px-5 py-2.5 bg-emerald-600 text-white rounded-xl font-bold hover:bg-emerald-700 transition-colors shadow-sm text-sm">Guardar Insumo</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {isAdjustOpen && currInsumo && (
        <div className="fixed inset-0 bg-gray-900/40 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
          <div className="bg-white rounded-3xl shadow-2xl w-full max-w-sm overflow-hidden animate-in zoom-in-95 duration-200">
            <div className="p-6 border-b border-gray-100 bg-gray-50/50 flex justify-between items-center">
              <div>
                <h3 className="text-xl font-black text-gray-900 leading-tight">Ajuste de Stock</h3>
                <p className="text-sm text-gray-500 mt-1">{currInsumo.nombre}</p>
              </div>
              <button onClick={() => setAdjustOpen(false)} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-200 transition-colors"><X className="w-5 h-5" /></button>
            </div>
            
            <form onSubmit={handleAdjust} className="p-6 pb-7">
              <div className="flex gap-4 mb-8">
                <label className={`flex-1 cursor-pointer border-2 rounded-2xl p-3 flex flex-col items-center justify-center gap-1 transition-all ${adjData.tipo === 'entrada' ? 'border-emerald-500 bg-emerald-50/50 text-emerald-700 shadow-sm' : 'border-gray-100 text-gray-400 hover:border-gray-200 hover:bg-gray-50'}`}>
                  <input type="radio" name="tipo" value="entrada" checked={adjData.tipo === 'entrada'} onChange={() => setAdjustData({...adjData, tipo: 'entrada'})} className="hidden" />
                  <ArrowUpRight className="w-6 h-6 mb-1" /> 
                  <span className="font-bold text-sm">Entrada</span>
                </label>
                <label className={`flex-1 cursor-pointer border-2 rounded-2xl p-3 flex flex-col items-center justify-center gap-1 transition-all ${adjData.tipo === 'salida' ? 'border-red-500 bg-red-50/50 text-red-700 shadow-sm' : 'border-gray-100 text-gray-400 hover:border-gray-200 hover:bg-gray-50'}`}>
                  <input type="radio" name="tipo" value="salida" checked={adjData.tipo === 'salida'} onChange={() => setAdjustData({...adjData, tipo: 'salida'})} className="hidden" />
                  <ArrowDownRight className="w-6 h-6 mb-1" /> 
                  <span className="font-bold text-sm">Salida</span>
                </label>
              </div>

              <div className="mb-8">
                <label className="block text-sm font-semibold text-gray-700 mb-2">Cantidad (kg)</label>
                <div className="relative">
                  <input required type="number" step="0.01" min="0.01" value={adjData.cant} onChange={e => setAdjustData({...adjData, cant: e.target.value})} className="w-full p-3.5 border border-gray-200 rounded-xl focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none text-right pr-12 font-bold text-gray-800 shadow-sm transition-all" placeholder="0" />
                  <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 font-bold text-sm">kg</span>
                </div>
                <p className="text-xs text-gray-500 mt-3 text-right">Stock actual: <strong className="text-gray-900 font-black">{currInsumo.cantidad_actual} kg</strong></p>
              </div>

              <button type="submit" className={`w-full py-3.5 rounded-xl font-bold text-white transition-colors shadow-sm text-sm ${adjData.tipo === 'entrada' ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-red-600 hover:bg-red-700'}`}>
                Confirmar {adjData.tipo === 'entrada' ? 'Entrada' : 'Salida'}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default InsumosView;