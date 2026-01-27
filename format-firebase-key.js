// Script para formatear la Firebase Private Key
// Ejecuta: node format-firebase-key.js

const fs = require('fs');

console.log('='.repeat(60));
console.log('FORMATEADOR DE FIREBASE PRIVATE KEY');
console.log('='.repeat(60));
console.log('\nInstrucciones:');
console.log('1. Descarga tu service account key de Firebase Console');
console.log('2. Busca el campo "private_key" en el archivo JSON');
console.log('3. Pégalo aquí abajo (reemplaza el placeholder)');
console.log('='.repeat(60));

// PEGA TU PRIVATE_KEY AQUÍ (entre las comillas)
const privateKey = `-----BEGIN PRIVATE KEY-----
PEGA_AQUI_TU_CLAVE_COMPLETA_INCLUYENDO_BEGIN_Y_END
-----END PRIVATE KEY-----`;

// Formatear para Supabase (escapar saltos de línea)
const formattedKey = privateKey
    .split('\n')
    .join('\\n');

console.log('\n✅ Clave formateada para Supabase:\n');
console.log(formattedKey);
console.log('\n' + '='.repeat(60));
console.log('\nAhora ejecuta:');
console.log(`npx supabase secrets set FIREBASE_PRIVATE_KEY="${formattedKey}" --project-ref tlzkddmquytddhdeqdmo`);
console.log('='.repeat(60));
