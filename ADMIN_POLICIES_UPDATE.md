# 🔐 Actualización de Políticas RLS para Panel de Administración

## ⚠️ IMPORTANTE: Debes aplicar estos cambios manualmente en Supabase Dashboard

Para que los administradores puedan crear/editar/eliminar usuarios desde la app, necesitas actualizar las políticas RLS (Row Level Security) en tu base de datos de Supabase.

---

## 📋 Pasos para Aplicar las Políticas

### 1️⃣ Abre Supabase Dashboard
1. Ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto de Comic Fest
3. Ve a **SQL Editor** en el menú lateral

### 2️⃣ Elimina las Políticas Antiguas
Ejecuta este SQL para eliminar las políticas actuales:

```sql
-- Eliminar políticas antiguas de profiles
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete_own" ON public.profiles;
```

### 3️⃣ Crea las Nuevas Políticas con Permisos de Admin
Ejecuta este SQL para crear las nuevas políticas:

```sql
-- Permitir INSERT: usuarios pueden crear su propio perfil O si son admin pueden crear cualquiera
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Permitir UPDATE: usuarios pueden actualizar su propio perfil O si son admin pueden actualizar cualquiera
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Permitir DELETE: usuarios solo pueden eliminar su propio perfil O si son admin pueden eliminar cualquiera
CREATE POLICY "profiles_delete_own" ON public.profiles
  FOR DELETE USING (
    auth.uid() = id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
```

### 4️⃣ Verifica que se Aplicaron Correctamente
1. Ve a **Authentication > Policies** en Supabase Dashboard
2. Selecciona la tabla `profiles`
3. Deberías ver las 3 políticas actualizadas: `profiles_insert_own`, `profiles_update_own`, `profiles_delete_own`

---

## ✅ ¿Qué Cambia con Estas Políticas?

### Antes:
- ❌ Solo podías crear/editar tu propio perfil
- ❌ Los admins NO podían crear usuarios para otros

### Después:
- ✅ Usuarios regulares pueden crear/editar solo su propio perfil
- ✅ Usuarios con rol `admin` pueden crear/editar/eliminar CUALQUIER perfil
- ✅ El panel de administración funciona correctamente

---

## 🧪 Cómo Probar

1. **Asegúrate de que tu usuario tenga rol `admin`**:
   - Ve a Supabase Dashboard → Table Editor → `profiles`
   - Encuentra tu perfil y edita el campo `role` a `'admin'`

2. **Inicia sesión en la app como admin**

3. **Ve al Panel de Administración** (debe aparecer en el menú lateral)

4. **Intenta crear un nuevo usuario** (expositor, artista, staff, etc.)

5. **Verifica que se creó correctamente** en la lista de usuarios

---

## ⚠️ Limitaciones Importantes

### ❌ Eliminación de Auth Users
- **NO es posible eliminar usuarios de Supabase Auth desde la app** (requiere Admin API que solo funciona del lado del servidor)
- Al hacer clic en "Eliminar Usuario", solo se **elimina el perfil** de la tabla `profiles`
- El usuario de autenticación permanece en `auth.users`
- **Para eliminar completamente un usuario**: Ve a Supabase Dashboard → Authentication → Users → Selecciona el usuario → Delete User

### ✅ Lo que SÍ funciona
- ✅ Crear nuevos usuarios con cualquier rol
- ✅ Editar perfiles existentes (nombre, rol)
- ✅ Ver lista completa de usuarios con filtros
- ✅ Estadísticas por tipo de usuario

---

## 🔄 Próximos Pasos Recomendados

Una vez aplicadas estas políticas, podrás:
1. **Crear usuarios de prueba** (expositores, artistas, staff)
2. **Poblar la base de datos** con eventos, productos, boletos
3. **Configurar las dinámicas de puntos**
4. **Probar el flujo completo offline-first**

---

## 📞 ¿Necesitas Ayuda?

Si tienes problemas aplicando estas políticas o algo no funciona como esperado, por favor avísame y revisaremos juntos los logs de Supabase.
