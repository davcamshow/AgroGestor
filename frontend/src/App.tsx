import React from 'react'

function App() {
  return (
    <div className="min-h-screen bg-gradient-to-r from-purple-500 to-pink-500 flex items-center justify-center">
      <div className="bg-white p-8 rounded-2xl shadow-2xl text-center">
        <h1 className="text-4xl font-bold text-gray-800 mb-4">
          🚀 React + TypeScript + Tailwind
        </h1>
        <p className="text-gray-600 text-lg">
          Todo funcionando correctamente
        </p>
        <button 
          className="mt-6 bg-purple-600 text-white px-6 py-3 rounded-lg hover:bg-purple-700 transition-colors"
          onClick={() => alert('¡Funciona!')}
        >
          Haz clic aquí
        </button>
      </div>
    </div>
  )
}

export default App
