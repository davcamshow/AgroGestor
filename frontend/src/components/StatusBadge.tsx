interface StatusBadgeProps {
  status: string;
}

const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const styles: Record<string, string> = {
    'Activo': 'bg-blue-100 text-blue-700 border-blue-200',
    'Activa': 'bg-emerald-100 text-emerald-700 border-emerald-200',
    'En revisión': 'bg-amber-100 text-amber-700 border-amber-200',
    'Archivada': 'bg-gray-100 text-gray-600 border-gray-200',
    'Crítico': 'bg-red-100 text-red-700 border-red-200',
    'Adecuado': 'bg-green-100 text-green-700 border-green-200',
    'Bajo': 'bg-orange-100 text-orange-700 border-orange-200',
    'Engorda': 'bg-purple-100 text-purple-700 border-purple-200',
    'Destete': 'bg-indigo-100 text-indigo-700 border-indigo-200',
    'Mantenimiento': 'bg-teal-100 text-teal-700 border-teal-200',
    'Lactancia': 'bg-pink-100 text-pink-700 border-pink-200',
  };
  
  const defaultStyle = 'bg-gray-100 text-gray-700 border-gray-200';
  const appliedStyle = styles[status] || defaultStyle;

  return (
    <span className={`px-2.5 py-1 rounded-full text-xs font-bold border ${appliedStyle}`}>
      {status}
    </span>
  );
};

export default StatusBadge;