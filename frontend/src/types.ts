export type { User, Lote, DietaIngrediente, Dieta, Insumo, ToastState };

interface User {
  name: string;
  email: string;
  password?: string;
  phone?: string;
  role?: string;
  license?: string;
  ranchName?: string;
  ranchAddress?: string;
}

interface Lote {
  id: number;
  nombre: string;
  cabezas: number;
  peso_promedio: number;
  etapa: string;
  estado: string;
  id_dieta: number | string;
}

interface DietaIngrediente {
  id_insumo: number | string;
  porcentaje: number | string;
}

interface Dieta {
  id: number;
  nombre: string;
  objetivo: string;
  fecha?: string;
  autor?: string;
  estado: string;
  costo_kg: number;
  ingredientes: DietaIngrediente[];
}

interface Insumo {
  id: number;
  nombre: string;
  cantidad_actual: number;
  stock_minimo: number;
  costo_kg: number;
}

interface ToastState {
  show: boolean;
  message: string;
  type: 'success' | 'error';
}
