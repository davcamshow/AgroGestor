import React, { useState } from "react";
import { type FormEvent } from "react";
import { User as UserIcon, Building, MapPin, Save } from "lucide-react";
import type { User } from "../types";

interface ConfiguracionViewProps {
  user: User | null;
  onUpdateUser: (user: User) => void;
  showToast: (msg: string, type?: 'success' | 'error') => void;
}

const ConfiguracionView: React.FC<ConfiguracionViewProps> = ({ user, onUpdateUser, showToast }) => {
  const [formData, setFormData] = useState<User>({
    name: user?.name || '', 
    email: user?.email || '', 
    phone: user?.phone || '', 
    role: user?.role || 'Médico Veterinario', 
    license: user?.license || '', 
    ranchName: user?.ranchName || '', 
    ranchAddress: user?.ranchAddress || ''
  });

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (user) {
      onUpdateUser({ ...user, ...formData });
      showToast('Configuración actualizada exitosamente', 'success');
    }
  };

  const inputClass = "w-full p-3 bg-white border border-gray-200 rounded-xl focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 outline-none transition-all text-sm font-medium text-gray-800 placeholder-gray-400 shadow-sm";
  const labelClass = "block text-xs font-bold text-gray-600 mb-1.5";

  return (
    <div className="animate-in fade-in duration-300 max-w-4xl mx-auto pb-12">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Configuración de la Cuenta</h1>
          <p className="text-gray-500 text-sm mt-1">Gestiona tu perfil profesional y los datos operativos de tu empresa.</p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
          <div className="p-5 border-b border-gray-100 flex items-center gap-3 bg-white">
            <div className="bg-emerald-50 p-2.5 rounded-xl text-emerald-600 border border-emerald-100/50">
              <UserIcon className="w-5 h-5" />
            </div>
            <h2 className="text-lg font-bold text-gray-900">Información del Profesional</h2>
          </div>
          <div className="p-8 grid grid-cols-1 sm:grid-cols-2 gap-7">
            <div>
              <label className={labelClass}>Nombre Completo *</label>
              <input required name="name" value={formData.name} onChange={e=>setFormData({...formData, name:e.target.value})} className={inputClass} placeholder="Ej. Dr. Roberto"/>
            </div>
            <div>
              <label className={labelClass}>Correo Electrónico *</label>
              <input required type="email" name="email" value={formData.email} onChange={e=>setFormData({...formData, email:e.target.value})} className={inputClass} placeholder="ejemplo@correo.com"/>
            </div>
            <div>
              <label className={labelClass}>Teléfono / WhatsApp</label>
              <input name="phone" value={formData.phone} onChange={e=>setFormData({...formData, phone:e.target.value})} className={inputClass} placeholder="Ej. 55 1234 5678"/>
            </div>
            <div>
              <label className={labelClass}>Rol / Profesión</label>
              <select name="role" value={formData.role} onChange={e=>setFormData({...formData, role:e.target.value})} className={`${inputClass} cursor-pointer`}>
                <option>Médico Veterinario</option>
                <option>Ing. Zootecnista</option>
                <option>Productor Ganadero</option>
                <option>Estudiante / Académico</option>
              </select>
            </div>
            <div className="sm:col-span-2">
              <label className={labelClass}>Cédula Profesional</label>
              <input name="license" value={formData.license} onChange={e=>setFormData({...formData, license:e.target.value})} className={inputClass} placeholder="No. de Cédula (Opcional)"/>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
          <div className="p-5 border-b border-gray-100 flex items-center gap-3 bg-white">
            <div className="bg-blue-50 p-2.5 rounded-xl text-blue-600 border border-blue-100/50">
              <Building className="w-5 h-5" />
            </div>
            <h2 className="text-lg font-bold text-gray-900">Datos de la Empresa / Rancho</h2>
          </div>
          <div className="p-8 flex flex-col gap-7">
            <div>
              <label className={labelClass}>Nombre del Rancho, Clínica o Empresa</label>
              <input name="ranchName" value={formData.ranchName} onChange={e=>setFormData({...formData, ranchName:e.target.value})} className={inputClass} placeholder="Ej. Ganadería La Esmeralda"/>
            </div>
            <div>
              <label className={labelClass}>Ubicación / Dirección Física</label>
              <div className="relative">
                <MapPin className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input name="ranchAddress" value={formData.ranchAddress} onChange={e=>setFormData({...formData, ranchAddress:e.target.value})} className={`${inputClass} pl-10`} placeholder="Ej. Carretera Nacional Km 45, Michoacán"/>
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-end pt-2">
          <button type="submit" className="flex items-center gap-2 bg-emerald-600 hover:bg-emerald-700 text-white px-6 py-3 rounded-xl font-bold transition-colors shadow-sm text-sm">
            <Save className="w-4 h-4" /> Guardar Cambios de Configuración
          </button>
        </div>
      </form>
    </div>
  );
};

export default ConfiguracionView;