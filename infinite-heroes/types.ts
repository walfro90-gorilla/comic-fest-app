
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
*/

export const MAX_STORY_PAGES = 10;
export const BACK_COVER_PAGE = 11;
export const TOTAL_PAGES = 11;
export const INITIAL_PAGES = 2;
export const GATE_PAGE = 2;
export const BATCH_SIZE = 6;
export const DECISION_PAGES = [3];

// Translated Genres
export const GENRES = [
    "Terror Clásico", 
    "Acción de Superhéroes", 
    "Ciencia Ficción Oscura", 
    "Alta Fantasía", 
    "Detective Neon Noir", 
    "Apocalipsis", 
    "Comedia Ligera", 
    "Drama Adolescente", 
    "Personalizado"
];

// Translated Tones
export const TONES = [
    "ACCIÓN PURA (Diálogos cortos. Enfoque cinético.)",
    "MONÓLOGO INTERNO (Muchos cuadros de pensamiento.)",
    "SARCÁSTICO (Humor como mecanismo de defensa.)",
    "DRAMÁTICO (Declaraciones grandes y teatrales.)",
    "CASUAL (Diálogo natural, chismes, relaciones.)",
    "OPTIMISTA (Cálido, gentil, esperanzador.)"
];

export const LANGUAGES = [
    { code: 'es-MX', name: 'Español (Mexicano)' },
    { code: 'en-US', name: 'Inglés (EE.UU.)' },
    { code: 'ja-JP', name: 'Japonés' }
];

export interface ComicFace {
  id: string;
  type: 'cover' | 'story' | 'back_cover';
  imageUrl?: string;
  narrative?: Beat;
  choices: string[];
  resolvedChoice?: string;
  isLoading: boolean;
  pageIndex?: number;
  isDecisionPage?: boolean;
}

export interface Beat {
  caption?: string;
  dialogue?: string;
  scene: string;
  choices: string[];
  focus_char: 'hero' | 'friend' | 'villain' | 'other';
}

export interface Persona {
  base64: string;
  desc: string; // Internal system desc
  name: string; // User defined name
  visualFeatures: string; // User defined visual traits (beard, glasses, etc)
}
