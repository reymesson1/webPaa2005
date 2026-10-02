# Onest Lite — App iOS Nativa

**Examen Práctico Desarrollador iOS — Onest Financial**  
*Septiembre / Octubre 2026*  
**Candidato:** Ricardo Messon  
**Stack:** Swift 5.9+, SwiftUI, iOS 16+, Swift Concurrency (`async/await`, `actor`), Apple Native Security (Keychain).  
**Dependencias externas:** 0 (Cero dependencias de terceros; 100% frameworks nativos de Apple).

---

## 1. Cómo Ejecutar el Proyecto

### Ejecución de la App
1. Abre el proyecto en Xcode:
   ```bash
   open Onest.xcodeproj
   ```
2. Selecciona el esquema **Onest** y cualquier simulador de iPhone con **iOS 16.0 o superior** (o dispositivo físico).
3. Presiona **Cmd + R** para compilar y ejecutar.
4. En la pantalla de Login, puedes usar los botones de acceso rápido para probar inmediatamente los flujos:
   - **Credenciales válidas (200)**: `usuario@onest.com` / `123456`
   - **Credenciales inválidas (401)**: `invalido@onest.com` / `invalid`

### Ejecución de la Suite de Pruebas Unitarias
El proyecto cuenta con una suite completa de pruebas unitarias ejecutables tanto desde Xcode como por línea de comandos:
```bash
./scripts/run_tests.sh
```
*Salida: 45 pruebas unitarias verificadas con 0 fallos.*

---

## 2. Contrato de la API Simulada

La simulación de red vive detrás de la **misma abstracción que usaría un backend real** utilizando `URLProtocol` (`SimulatedURLProtocol`) y `URLSession`. Toda llamada genera peticiones `URLRequest` reales a `https://api.onest.com`, decodifica respuestas HTTP reales (`HTTPURLResponse`) y procesa errores por código de estado.

| Método | Ruta | Status Normal | Escenarios Obligatorios y Casos Borde |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/login` | **200 OK** con tokens y usuario | **401 Unauthorized** con credenciales inválidas. Access token expira en 60s. |
| `POST` | `/auth/refresh` | **200 OK** con tokens renovados | **401 Unauthorized** si el refresh token expiró (fuerza cierre de sesión). |
| `GET` | `/loans` | **200 OK** lista de préstamos | **401 Unauthorized** si access token expiró. Latencia aleatoria de 0.5s a 2.0s. |
| `GET` | `/loans/{id}` | **200 OK** detalle y calendario | **404 Not Found** si el ID de préstamo no existe. |
| `POST` | `/loans/quote` | **200 OK** cuota, tasa y costo | **422 Unprocessable Entity** si monto < 5,000 o > 100,000 DOP, o plazo fuera de 3-24 meses. |
| `POST` | `/loans` | **201 Created** (`EN_REVISION`) | **500 Internal Server Error** intermitente (1 de cada 4). Requiere `Idempotency-Key`: si se repite la llave, devuelve el mismo préstamo sin duplicar. |

### Ejemplos de Cargas JSON

#### `POST /auth/login`
```json
// Request
{ "username": "usuario@onest.com", "password": "123456" }

// Response (200)
{
  "accessToken": "acc_a8b2c1_1727823600",
  "refreshToken": "ref_9f8e7d_1727823600",
  "expiresIn": 60,
  "tokenType": "Bearer",
  "user": { "id": "usr_1001", "name": "Ricardo Messon", "email": "usuario@onest.com" }
}
```

#### `POST /loans/quote`
```json
// Request
{ "amount": 25000.0, "termMonths": 6 }

// Response (200)
{
  "amount": 25000.0,
  "termMonths": 6,
  "annualRate": 0.18,
  "monthlyPayment": 4386.42,
  "totalCost": 26318.52,
  "totalInterest": 1318.52
}
```

#### `POST /loans` (Headers: `Idempotency-Key: 7B5C3D4A-...`)
```json
// Response (201 Created)
{
  "id": "LOAN-2026",
  "amount": 25000.0,
  "remainingBalance": 25000.0,
  "nextPaymentDate": "2026-11-01T00:00:00Z",
  "status": "EN_REVISION",
  "termMonths": 6,
  "interestRate": 0.18,
  "monthlyPayment": 4386.42,
  "totalCost": 26318.52,
  "createdAt": "2026-10-01T19:30:00Z",
  "installments": [ ... ]
}
```

---

## 3. Arquitectura Elegida y Justificación

Se adoptó una arquitectura **Clean Architecture + MVVM + Coordinador de Estado**, orientada a aislamiento y testabilidad:

```
Onest/
├── features/
│   ├── Core/
│   │   ├── Models/       # Entidades de dominio inmutables (Sendable, Codable)
│   │   ├── Security/     # Abstracción de Keychain y almacenamiento seguro
│   │   ├── Network/      # APIClient, TokenRefreshCoordinator (actor), SimulatedURLProtocol
│   │   ├── Services/     # AuthService y LoanService con interfaces protocolizadas
│   │   ├── Utils/        # Formateadores locales DOP (RD$ #,##0.00) y Theme
│   │   └── Components/   # Componentes visuales reutilizables (Badges, Buttons, Inputs)
│   ├── Auth/             # LoginView, LoginViewModel
│   ├── Loans/            # LoansListView, LoansViewModel, LoanCardView
│   ├── LoanDetail/       # LoanDetailView, LoanDetailViewModel, PaymentCalendarView
│   ├── LoanApplication/  # Flujo guiado en 3 pasos con cálculo de cuotas e idempotencia
│   └── Home/             # Dashboard principal, perfil, sandbox de pruebas para el revisor
```

### ¿Por qué esta arquitectura?
1. **Desacoplamiento total del transporte de red**: La app no tiene conocimiento de que la red es simulada. La inyección de `SimulatedURLProtocol` en la `URLSessionConfiguration` permite que, en el momento de conectar un backend real en producción, **no sea necesario cambiar una sola línea de código** de servicios, ViewModels o vistas.
2. **Concurrencia segura con Swift Actors**: La sincronización de tokens utiliza un `actor TokenRefreshCoordinator`. Cuando múltiples peticiones se ejecutan concurrentemente con el token expirado, el actor deduplica las solicitudes ejecutando **una sola petición de red de refresco** y resolviendo todas las llamadas en espera con el nuevo token.
3. **Manejo de Idempotencia**: El ViewModel de solicitud genera y preserva un `Idempotency-Key` persistente ante fallos 500 intermitentes, permitiendo reintentos seguros sin duplicación de créditos.

---

## 4. Decisiones de Seguridad

1. **Tokens en Apple Keychain**:
   - Se utiliza la API nativa de `Security.framework` (`kSecClassGenericPassword`).
   - Se configuró el nivel de protección de hardware `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: las credenciales solo son legibles tras el primer desbloqueo del dispositivo y nunca viajan en copias de seguridad de iCloud o a otros equipos.
2. **Cierre de Sesión Seguro**:
   - `AuthService.logout()` invoca `KeychainManager.clearSession()`, eliminando de inmediato todos los registros del Keychain y notificando al coordinador para purgar el estado en memoria y devolver al usuario a la pantalla de Login.
3. **Persistencia de Sesión Segura**:
   - Al lanzar la app, el coordinador valida si existe una sesión válida o renovable en el Keychain. Si el token está vigente o puede refrescarse, restaura la navegación; de lo contrario, solicita autenticación.

---

## 5. Pruebas Unitarias Implementadas

Se cubrieron los requerimientos obligatorios con pruebas automatizadas (`OnestTests/`):

1. **Renovación Concurrente de Token (`TokenRefreshTests.swift`)**:
   - 10 peticiones concurrentes con token expirado ejecutadas en paralelo (`withThrowingTaskGroup`).
   - Verificación de que `refreshExecutionCount == 1` (deduplicación atómica).
   - Verificación de fallo y deslogueo automático si el refresh token expira (401).
2. **Validación del Formulario de Solicitud (`LoanApplicationValidationTests.swift`)**:
   - Límites inferior (< RD$ 5,000) y superior (> RD$ 100,000).
   - Límites de plazo (< 3 meses y > 24 meses).
   - Preservación de `Idempotency-Key` ante fallos 500 intermitentes para reintento idéntico.
   - Obligatoriedad de aceptación de términos y condiciones.
3. **ViewModels (`LoansViewModelTests.swift`, `LoginViewModelTests.swift`)**:
   - Estados de carga, pull-to-refresh, filtrado por estado (`EN_REVISION`, `DESEMBOLSADO`, etc.).
   - Cálculo del total de deuda pendiente y conteo de préstamos activos.
   - Validación reactiva de credenciales y mensajes de error 401.
4. **Persistencia en Keychain (`KeychainManagerTests.swift`)**:
   - Guardado, lectura, actualización y borrado completo en cierre de sesión.

---

## 6. Qué se Dejó Fuera y Plan a 2 Semanas

### Lo que se dejó fuera por alcance del examen:
- **Biometría (Face ID / Touch ID)**: Desbloqueo rápido mediante `LocalAuthentication` vinculado a claves biométricas en Keychain.
- **Cache Offline persistente**: Almacenamiento local con SwiftData/CoreData para modo avión.
- **Firma digital biométrica**: Módulo de firma de pagaré electrónico en el paso 3 de solicitud.

### Plan de trabajo con dos semanas adicionales:
1. **Semana 1**:
   - Implementación de **Face ID / Touch ID** con fallback a PIN local.
   - Capa de **Persistencia Offline con SwiftData**, cacheando préstamos y calendarios con sincronización en segundo plano mediante `BackgroundTasks`.
   - Soporte para **Notificaciones Push (APNs)** para alertar cambios de estado en revisiones y vencimientos de cuotas.
2. **Semana 2**:
   - Cobertura de **Pruebas de Snapshot UI** para verificar consistencia visual en diferentes tamaños de pantalla (iPhone SE hasta iPhone 16 Pro Max) y modo oscuro.
   - Flujo de **pago de cuotas** con tarjeta de débito / transferencia local.
   - Pipeline de **CI/CD con GitHub Actions** para validación automática de compilación, linter (SwiftLint) y ejecución de pruebas unitarias en cada Pull Request.

---

## 7. Declaración de Uso de Asistentes de IA

En conformidad con las pautas de la prueba técnica, se utilizaron asistentes de inteligencia artificial (Google Antigravity / Gemini) como herramienta de apoyo para pair programming, scaffolding y verificación de casos de prueba. La arquitectura, modelado del dominio, algoritmos de concurrencia y decisiones técnicas fueron diseñadas e implementadas con criterio profesional y estoy plenamente preparado para defender cualquier línea de código y realizar modificaciones en vivo durante la entrevista técnica.
