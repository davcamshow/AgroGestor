import React from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
}

export const Input = ({ label, ...props }: InputProps) => (
  <div className="space-y-1.5 w-full">
    <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide">
      {label}
    </label>
    <input
      {...props}
      className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:bg-white focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500 outline-none transition-all text-sm shadow-sm"
    />
  </div>
);