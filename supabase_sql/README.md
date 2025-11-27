# 📋 Scripts SQL para Supabase - Comic Fest

## 📂 Orden de Ejecución

Ejecuta los scripts en **Supabase Dashboard → SQL Editor** en el siguiente orden:

### 1️⃣ `01_create_tables.sql`
Crea todas las tablas de la base de datos:
- profiles
- map_points
- schedule_items
- tickets
- exhibitor_details
- products
- points_log
- promotions
- contests
- contest_entries
- votes
- passport_stamps
- orders

### 2️⃣ `02_create_indexes.sql`
Crea índices para mejorar el rendimiento de las consultas más comunes.

### 3️⃣ `03_create_triggers.sql`
Crea funciones y triggers para:
- Actualización automática de `updated_at`
- Creación automática de perfiles cuando un usuario se registra

### 4️⃣ `04_create_policies.sql`
Configura Row Level Security (RLS) y políticas de acceso para todas las tablas.

---

## 🚀 Instrucciones de Uso

1. **Abre Supabase Dashboard**
   - Ve a: https://supabase.com/dashboard
   - Selecciona tu proyecto de Comic Fest

2. **Abre SQL Editor**
   - En el menú lateral: **SQL Editor** → **New query**

3. **Ejecuta los scripts en orden**
   - Copia el contenido de `01_create_tables.sql`
   - Pégalo en el editor SQL
   - Haz clic en **Run** (▶️)
   - Repite para los scripts 02, 03 y 04

4. **Verifica las tablas**
   - Ve a **Table Editor** en el menú lateral
   - Deberías ver todas las tablas creadas

---

## ⚠️ Notas Importantes

- **No modifiques el orden**: Los scripts tienen dependencias entre sí
- **Políticas DROP IF EXISTS**: Los scripts eliminan políticas existentes antes de crearlas, así que son seguros de ejecutar múltiples veces
- **Row Level Security**: Todas las tablas tienen RLS habilitado para seguridad

---

## 🔐 Roles y Permisos

El sistema maneja los siguientes roles:
- **attendee**: Asistente regular (rol por defecto)
- **exhibitor**: Expositor/Vendedor
- **artist**: Artista invitado
- **staff**: Personal del evento
- **admin**: Administrador completo

---

## 📊 Estructura de la Base de Datos

```
┌─────────────────┐
│   auth.users    │ (Supabase Auth)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    profiles     │ ◄─── Perfil de usuario
└────────┬────────┘
         │
         ├──────► tickets (boletos)
         ├──────► points_log (transacciones de puntos)
         ├──────► votes (votos en concursos)
         ├──────► passport_stamps (sellos virtuales)
         └──────► orders (pedidos)

┌─────────────────┐
│  schedule_items │ ◄─── Eventos del festival
└─────────────────┘

┌─────────────────┐
│    products     │ ◄─── Productos de la tienda
└─────────────────┘

┌─────────────────┐
│    contests     │ ◄─── Concursos y votaciones
└────────┬────────┘
         │
         └──────► contest_entries (participantes)
```

---

## 🆘 Solución de Problemas

### Error: "relation already exists"
✅ Esto es normal si las tablas ya existen. Los scripts usan `CREATE TABLE IF NOT EXISTS`.

### Error: "policy already exists"
✅ Los scripts eliminan políticas existentes con `DROP POLICY IF EXISTS` antes de crearlas.

### Error: "permission denied"
❌ Asegúrate de estar ejecutando los scripts como usuario admin en Supabase Dashboard.

---

## 📝 Próximos Pasos

Después de ejecutar todos los scripts:

1. **Crea tu usuario admin**:
   - Regístrate en la app
   - Ve a **Table Editor** → **profiles**
   - Cambia tu `role` de `'attendee'` a `'admin'`

2. **Genera datos de prueba**:
   - Usa el Panel de Administración en la app
   - Botón: "Generar Datos de Prueba"

3. **¡Listo para usar!** 🎉
