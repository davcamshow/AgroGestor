import type { ReactNode } from "react";
import { Plus } from "lucide-react";

interface EmptyStateProps {
  icon: ReactNode;
  title: string;
  description: string;
  actionText?: string;
  onAction?: () => void;
}

const EmptyState: React.FC<EmptyStateProps> = ({ icon, title, description, actionText, onAction }) => (
  <div className="flex flex-col items-center justify-center p-12 bg-white rounded-xl border border-gray-100 border-dashed text-center">
    <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center text-gray-400 mb-4">
      {icon}
    </div>
    <h3 className="text-lg font-bold text-gray-900 mb-1">{title}</h3>
    <p className="text-gray-500 text-sm max-w-sm mb-6">{description}</p>
    {actionText && (
      <button onClick={onAction} className="flex items-center gap-2 bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 px-4 py-2 rounded-lg font-medium transition-colors shadow-sm text-sm">
        <Plus className="w-4 h-4" /> {actionText}
      </button>
    )}
  </div>
);

export default EmptyState;

