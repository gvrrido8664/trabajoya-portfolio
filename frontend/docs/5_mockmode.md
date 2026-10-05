# Modo Mock / Demo

La app tiene un modo mock que reemplaza todas las llamadas a la API con datos simulados en memoria.  
No requiere backend, base de datos, ni conexion a internet.

## Activar / Desactivar

Editar `lib/core/constants.dart`:

```dart
const mockMode = true;   // ← activado: la app usa datos falsos
const mockMode = false;  // ← desactivado: la app se conecta a la API real
```

Luego correr la app normalmente:

```
flutter run
```

## Que cambia con mockMode = true

- `ApiClient.get`, `.post`, `.put`, `.patch`, `.delete` y `.uploadMultipart` no hacen llamadas HTTP.
- En su lugar, `MockApi.handle()` en `lib/core/mock_data.dart` retorna datos precargados.
- Los datos incluyen 4 usuarios, 8 servicios, 3 contrataciones, mensajes, resenas y panel admin.
- La latencia de red se simula con ~200ms de delay.

## Como probar distintos roles en el login

Cualquier email y password funciona. El rol asignado depende del texto del email:

| El email contiene... | Rol asignado |
|---|---|
| `admin` | Administrador |
| `carlos` o `proveedor` | Proveedor (Carlos Perez, gasfiter) |
| `ana` | Proveedora (Ana Martinez, electricista) |
| Cualquier otra cosa | Cliente (Maria Gonzalez) |

## Datos incluidos

| Tipo | Cantidad |
|---|---|
| Usuarios | 4 (1 cliente, 2 proveedores, 1 admin) |
| Servicios | 8 (4 gasfiteria, 4 electricidad) |
| Contrataciones | 3 (completada, aceptada, pendiente) |
| Mensajes | 5 en 2 conversaciones |
| Resenas | 1 |
| Suscripcion | 1 (premium activa) |

## Volver al backend real

1. Cambiar `mockMode` a `false` en `lib/core/constants.dart`
2. Asegurarse de que el backend este corriendo en `localhost:8000`
3. `flutter run`

El mock no interfiere con el codigo real: todas las rutas de API, modelos y servicios siguen intactos.
