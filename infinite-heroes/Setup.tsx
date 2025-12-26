
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
*/

import React, { useState, useEffect } from 'react';
import { GENRES, LANGUAGES, Persona } from './types';

interface SetupProps {
    show: boolean;
    isTransitioning: boolean;
    hero: Persona | null;
    friend: Persona | null;
    villain: Persona | null;
    selectedGenre: string;
    selectedLanguage: string;
    customPremise: string;
    richMode: boolean;
    onHeroUpload: (file: File) => void;
    onFriendUpload: (file: File) => void;
    onVillainUpload: (file: File) => void;
    onUpdatePersona: (type: 'hero' | 'friend' | 'villain', updates: Partial<Persona>) => void;
    onGenreChange: (val: string) => void;
    onLanguageChange: (val: string) => void;
    onPremiseChange: (val: string) => void;
    onRichModeChange: (val: boolean) => void;
    onLaunch: () => void;
}

const Footer = () => {
  const [remixIndex, setRemixIndex] = useState(0);
  const remixes = [
    "Añade efectos de sonido",
    "Anima los paneles con Veo",
    "Traduce a Klingon",
    "Imprime copias físicas",
    "Añade narración de voz",
    "Crea un universo compartido"
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setRemixIndex(prev => (prev + 1) % remixes.length);
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-black text-white py-3 px-6 hidden md:flex flex-col md:flex-row justify-between items-center z-[300] border-t-4 border-yellow-400 font-comic">
        <div className="flex items-center gap-2 text-lg md:text-xl">
            <span className="text-yellow-400 font-bold">IDEA REMIX:</span>
            <span className="animate-pulse">{remixes[remixIndex]}</span>
        </div>
        <div className="flex items-center gap-4 mt-2 md:mt-0">
            <span className="text-gray-500 text-sm hidden md:inline">Hecho con Gemini</span>
            <a href="https://x.com/ammaar" target="_blank" rel="noopener noreferrer" className="text-white hover:text-yellow-400 transition-colors text-xl">Creado por @ammaar</a>
        </div>
    </div>
  );
};

export const Setup: React.FC<SetupProps> = (props) => {
    if (!props.show && !props.isTransitioning) return null;

    const renderCharacterInput = (
        role: string, 
        colorClass: string, 
        bgClass: string, 
        data: Persona | null, 
        onUpload: (f: File) => void,
        type: 'hero' | 'friend' | 'villain'
    ) => (
        <div className={`p-2 border-4 border-dashed ${data ? 'border-green-500 bg-green-50' : `${colorClass} ${bgClass}`} transition-colors relative group`}>
            <div className="flex justify-between items-center mb-1">
                <p className={`font-comic text-lg uppercase font-bold text-black`}>{role}</p>
                {data && <span className="text-green-600 font-bold font-comic text-sm animate-pulse">✓ LISTO</span>}
            </div>
            
            {data ? (
                <div className="flex gap-2 items-start mt-1">
                    <img src={`data:image/jpeg;base64,${data.base64}`} alt="Preview" className="w-20 h-20 md:w-24 md:h-24 object-cover border-2 border-black shadow-[2px_2px_0px_rgba(0,0,0,0.2)] bg-white rotate-[-1deg]" />
                    <div className="flex-1 flex flex-col gap-1">
                        <input 
                            type="text" 
                            placeholder="Nombre (ej. Alex)" 
                            value={data.name}
                            onChange={(e) => props.onUpdatePersona(type, { name: e.target.value })}
                            className="w-full border-2 border-black p-1 font-comic text-sm"
                        />
                        <textarea 
                            placeholder="Rasgos Físicos (IMPORTANTE para consistencia: Barba, cicatriz, lentes, color de ropa...)"
                            value={data.visualFeatures}
                            onChange={(e) => props.onUpdatePersona(type, { visualFeatures: e.target.value })}
                            className="w-full border-2 border-black p-1 font-comic text-sm h-12 resize-none leading-tight"
                        />
                        <label className="cursor-pointer comic-btn bg-yellow-400 text-black text-xs px-2 py-1 hover:bg-yellow-300 text-center uppercase mt-1">
                            CAMBIAR FOTO
                            <input type="file" accept="image/*" className="hidden" onChange={(e) => e.target.files?.[0] && onUpload(e.target.files[0])} />
                        </label>
                    </div>
                </div>
            ) : (
                <label className={`comic-btn ${type === 'hero' ? 'bg-blue-500' : type === 'friend' ? 'bg-purple-500' : 'bg-red-600'} text-white text-lg px-3 py-4 block w-full hover:opacity-90 cursor-pointer text-center uppercase`}>
                    SUBIR FOTO
                    <input type="file" accept="image/*" className="hidden" onChange={(e) => e.target.files?.[0] && onUpload(e.target.files[0])} />
                </label>
            )}
        </div>
    );

    return (
        <>
        <style>{`
             @keyframes knockout-exit {
                0% { transform: scale(1) rotate(1deg); }
                15% { transform: scale(1.1) rotate(-5deg); }
                100% { transform: translateY(-200vh) rotate(1080deg) scale(0.5); opacity: 1; }
             }
             @keyframes pow-enter {
                 0% { transform: translate(-50%, -50%) scale(0) rotate(-45deg); opacity: 0; }
                 30% { transform: translate(-50%, -50%) scale(1.5) rotate(10deg); opacity: 1; }
                 100% { transform: translate(-50%, -50%) scale(1.8) rotate(0deg); opacity: 0; }
             }
          `}</style>
        {props.isTransitioning && (
            <div className="fixed top-1/2 left-1/2 z-[210] pointer-events-none" style={{ animation: 'pow-enter 1s forwards ease-out' }}>
                <svg viewBox="0 0 200 150" className="w-[500px] h-[400px] drop-shadow-[0_10px_0_rgba(0,0,0,0.5)]">
                    <path d="M95.7,12.8 L110.2,48.5 L148.5,45.2 L125.6,74.3 L156.8,96.8 L119.4,105.5 L122.7,143.8 L92.5,118.6 L60.3,139.7 L72.1,103.2 L34.5,108.8 L59.9,79.9 L24.7,57.3 L62.5,54.4 L61.2,16.5 z" fill="#FFD700" stroke="black" strokeWidth="4"/>
                    <text x="100" y="95" textAnchor="middle" fontFamily="'Bangers', cursive" fontSize="70" fill="#DC2626" stroke="black" strokeWidth="2" transform="rotate(-5 100 75)">POW!</text>
                </svg>
            </div>
        )}
        
        <div className={`fixed inset-0 z-[200] overflow-y-auto`}
             style={{
                 background: props.isTransitioning ? 'transparent' : 'rgba(0,0,0,0.85)', 
                 backdropFilter: props.isTransitioning ? 'none' : 'blur(6px)',
                 animation: props.isTransitioning ? 'knockout-exit 1s forwards cubic-bezier(.6,-0.28,.74,.05)' : 'none',
                 pointerEvents: props.isTransitioning ? 'none' : 'auto'
             }}>
          <div className="min-h-full flex items-start md:items-center justify-center p-2 md:p-4 pb-24">
            <div className="max-w-[900px] w-full bg-white p-3 md:p-5 rotate-1 border-[4px] md:border-[6px] border-black shadow-[8px_8px_0px_rgba(0,0,0,0.6)] md:shadow-[12px_12px_0px_rgba(0,0,0,0.6)] text-center relative mt-4 md:mt-0">
                
                <h1 className="font-comic text-4xl md:text-5xl text-red-600 leading-none mb-1 tracking-wide inline-block mr-3" style={{textShadow: '2px 2px 0px black'}}>INFINITE</h1>
                <h1 className="font-comic text-4xl md:text-5xl text-yellow-400 leading-none mb-4 tracking-wide inline-block" style={{textShadow: '2px 2px 0px black'}}>HEROES</h1>
                
                <div className="flex flex-col md:flex-row gap-4 mb-4 text-left">
                    
                    {/* Left Column: Cast */}
                    <div className="flex-1 flex flex-col gap-2">
                        <div className="font-comic text-xl text-black border-b-4 border-black mb-1">1. EL REPARTO</div>
                        <div className="grid grid-cols-1 gap-2">
                            {renderCharacterInput(
                                "HÉROE (REQUERIDO)", 
                                "border-blue-300", "bg-blue-50", 
                                props.hero, props.onHeroUpload, 'hero'
                            )}
                            {renderCharacterInput(
                                "CO-PROTAGONISTA (OPCIONAL)", 
                                "border-purple-300", "bg-purple-50", 
                                props.friend, props.onFriendUpload, 'friend'
                            )}
                            {renderCharacterInput(
                                "VILLANO (OPCIONAL)", 
                                "border-red-300", "bg-red-50", 
                                props.villain, props.onVillainUpload, 'villain'
                            )}
                        </div>
                    </div>

                    {/* Right Column: Settings */}
                    <div className="flex-1 flex flex-col gap-2">
                        <div className="font-comic text-xl text-black border-b-4 border-black mb-1">2. LA HISTORIA</div>
                        
                        <div className="bg-yellow-50 p-3 border-4 border-black h-full flex flex-col justify-between">
                            <div>
                                <div className="mb-2">
                                    <p className="font-comic text-base mb-1 font-bold text-gray-800">GÉNERO</p>
                                    <select value={props.selectedGenre} onChange={(e) => props.onGenreChange(e.target.value)} className="w-full font-comic text-lg p-2 border-2 border-black uppercase bg-white text-black cursor-pointer shadow-[3px_3px_0px_rgba(0,0,0,0.2)] focus:outline-none focus:translate-x-[1px] focus:translate-y-[1px] focus:shadow-none transition-all">
                                        {GENRES.map(g => <option key={g} value={g} className="text-black">{g}</option>)}
                                    </select>
                                </div>

                                <div className="mb-2">
                                    <p className="font-comic text-base mb-1 font-bold text-gray-800">IDIOMA</p>
                                    <select value={props.selectedLanguage} onChange={(e) => props.onLanguageChange(e.target.value)} className="w-full font-comic text-lg p-2 border-2 border-black uppercase bg-white text-black cursor-pointer shadow-[3px_3px_0px_rgba(0,0,0,0.2)]">
                                        {LANGUAGES.map(l => <option key={l.code} value={l.code} className="text-black">{l.name}</option>)}
                                    </select>
                                </div>

                                {props.selectedGenre === 'Personalizado' && (
                                    <div className="mb-2">
                                        <p className="font-comic text-base mb-1 font-bold text-gray-800">PREMISA</p>
                                        <textarea value={props.customPremise} onChange={(e) => props.onPremiseChange(e.target.value)} placeholder="Escribe tu premisa..." className="w-full p-2 border-2 border-black font-comic text-lg h-24 resize-none shadow-[3px_3px_0px_rgba(0,0,0,0.2)]" />
                                    </div>
                                )}
                            </div>
                            
                            <label className="flex items-center gap-2 font-comic text-base cursor-pointer text-black mt-2 p-2 hover:bg-yellow-100 rounded border-2 border-transparent hover:border-yellow-300 transition-colors">
                                <input type="checkbox" checked={props.richMode} onChange={(e) => props.onRichModeChange(e.target.checked)} className="w-5 h-5 accent-black" />
                                <span className="text-black">MODO NOVELA (Diálogos Ricos)</span>
                            </label>
                        </div>
                    </div>
                </div>

                <button onClick={props.onLaunch} disabled={!props.hero || props.isTransitioning} className="comic-btn bg-red-600 text-white text-2xl md:text-3xl px-6 py-4 w-full hover:bg-red-500 disabled:bg-gray-400 disabled:cursor-not-allowed uppercase tracking-wider mb-2">
                    {props.isTransitioning ? 'INICIANDO...' : '¡COMENZAR AVENTURA!'}
                </button>
            </div>
          </div>
        </div>

        {/* Footer is only visible when setup is active */}
        <Footer />
        </>
    );
}
