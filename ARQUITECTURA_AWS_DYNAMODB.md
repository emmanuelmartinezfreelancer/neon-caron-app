# Arquitectura AWS + DynamoDB para Neon Caron

## 🏗️ Arquitectura Completa AWS

### Stack Tecnológico AWS:

```
iOS App (Swift)
    ↓ HTTPS/REST
API Gateway (AWS)
    ↓
Lambda Functions (Node.js/Python)
    ↓
DynamoDB (Base de Datos)
    ↓
S3 (Almacenamiento de imágenes/videos)
```

### Servicios AWS Necesarios:

1. **AWS Cognito** - Autenticación (Gmail + Email/Password)
2. **API Gateway** - Endpoint REST para la app
3. **Lambda** - Lógica de negocio (serverless)
4. **DynamoDB** - Base de datos NoSQL
5. **S3** - Almacenamiento de imágenes de image trackers
6. **CloudFront** (Opcional) - CDN para videos/imágenes

---

## 📐 Arquitectura en iOS (Cliente)

### Estructura de Capas:

```
┌─────────────────────────────────────┐
│   ViewController (UI)                │
│   - HomeViewController               │
│   - LoginViewController              │
│   - CreateCollectionViewController   │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   Repository (Lógica de Negocio)     │
│   - CollectionRepository            │
│   - UserRepository                  │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│   Services (Efectos Secundarios)    │
│   - APIService (HTTP calls)         │
│   - CognitoService (Auth)           │
│   - CoreDataManager (Local cache)   │
└──────────────┬──────────────────────┘
               │
       ┌───────┴───────┐
       │               │
       ↓               ↓
┌──────────────┐  ┌──────────────┐
│ API Gateway  │  │ Core Data    │
│ (AWS)        │  │ (Local)      │
└──────────────┘  └──────────────┘
```

---

## 🔑 Diferencias Clave: Firebase vs AWS

| Aspecto | Firebase | AWS |
|---------|----------|-----|
| **Conexión** | SDK directo desde iOS | API REST (HTTP) |
| **Autenticación** | Firebase Auth | AWS Cognito |
| **Base de Datos** | Firestore SDK directo | DynamoDB vía API |
| **¿Necesitas API?** | ❌ NO | ✅ SÍ (API Gateway + Lambda) |
| **Arquitectura** | Cliente → Firebase | Cliente → API → Lambda → DynamoDB |

---

## 📁 Estructura de Archivos en iOS

```
Neon Caron/
├── Controllers/
│   ├── HomeViewController.swift
│   ├── LoginViewController.swift
│   └── CreateCollectionViewController.swift
│
├── Repositories/          ← Lógica de Negocio
│   ├── CollectionRepository.swift
│   └── UserRepository.swift
│
├── Services/              ← Efectos Secundarios
│   ├── APIService.swift           (HTTP calls a API Gateway)
│   ├── CognitoService.swift       (AWS Cognito Auth)
│   ├── CoreDataManager.swift      (Cache local)
│   └── S3Service.swift            (Upload imágenes)
│
├── Models/
│   ├── User.swift
│   ├── UserCollection.swift
│   ├── UserPainting.swift
│   └── APIResponse.swift          (Modelos para respuestas API)
│
└── Common/
    └── PaintingCollections.swift (mantener para colecciones estáticas)
```

---

## 🔄 Flujo Completo: Crear Colección

### En iOS:
```
Usuario toca "Create Collection +"
    ↓
CreateCollectionViewController
    ↓
collectionRepository.createCollection(collection)
    ↓
CollectionRepository:
    1. Valida datos (lógica de negocio)
    2. apiService.createCollection(collection) (HTTP POST)
    3. coreDataManager.save(collection) (cache local)
    4. Retorna resultado
    ↓
ViewController actualiza UI
```

### En AWS:
```
APIService hace HTTP POST
    ↓
API Gateway recibe request
    ↓
Lambda Function (createCollection)
    1. Valida token de Cognito
    2. Procesa datos
    3. Guarda en DynamoDB
    4. Retorna respuesta
    ↓
iOS recibe respuesta JSON
```

---

## 🛠️ Implementación en iOS

### 1. APIService (HTTP Calls)

```swift
// Services/APIService.swift
import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod"
    private let session = URLSession.shared
    
    // Headers con token de autenticación
    private func headers() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        if let token = CognitoService.shared.getAccessToken() {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    // Crear colección
    func createCollection(_ collection: UserCollection, completion: @escaping (Result<UserCollection, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/collections")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers()
        
        do {
            request.httpBody = try JSONEncoder().encode(collection)
        } catch {
            completion(.failure(error))
            return
        }
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let collection = try JSONDecoder().decode(UserCollection.self, from: data)
                completion(.success(collection))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Obtener colecciones de usuario
    func getUserCollections(userId: String, completion: @escaping (Result<[UserCollection], Error>) -> Void) {
        let url = URL(string: "\(baseURL)/users/\(userId)/collections")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers()
        
        session.dataTask(with: request) { data, response, error in
            // Procesar respuesta...
        }.resume()
    }
}

enum APIError: Error {
    case noData
    case invalidResponse
    case unauthorized
}
```

### 2. CognitoService (Autenticación)

```swift
// Services/CognitoService.swift
import Foundation
// Nota: Necesitarás importar AWS SDK cuando lo agregues

class CognitoService {
    static let shared = CognitoService()
    
    private var accessToken: String?
    
    // Login con Gmail (usando Cognito Identity Provider)
    func signInWithGoogle(completion: @escaping (Result<User, Error>) -> Void) {
        // Implementar con AWS Cognito SDK
        // Esto requiere configuración de Cognito Identity Provider
    }
    
    // Login con Email/Password
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        // Implementar con AWS Cognito SDK
    }
    
    // Obtener token de acceso
    func getAccessToken() -> String? {
        return accessToken
    }
    
    // Logout
    func signOut() {
        accessToken = nil
    }
}
```

### 3. CollectionRepository (Lógica de Negocio)

```swift
// Repositories/CollectionRepository.swift
import Foundation

class CollectionRepository {
    static let shared = CollectionRepository()
    
    private let apiService = APIService.shared
    private let coreDataManager = CoreDataManager.shared
    
    // Crear colección
    func createCollection(_ collection: UserCollection, completion: @escaping (Result<UserCollection, Error>) -> Void) {
        // 1. Validar datos (lógica de negocio)
        guard !collection.name.isEmpty else {
            completion(.failure(ValidationError.emptyName))
            return
        }
        
        // 2. Guardar en API (efecto secundario)
        apiService.createCollection(collection) { [weak self] result in
            switch result {
            case .success(let savedCollection):
                // 3. Guardar en Core Data para cache (efecto secundario)
                self?.coreDataManager.saveCollection(savedCollection)
                completion(.success(savedCollection))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Obtener colecciones (con cache local)
    func getUserCollections(userId: String, completion: @escaping (Result<[UserCollection], Error>) -> Void) {
        // 1. Intentar cargar desde Core Data (rápido, offline)
        if let localCollections = coreDataManager.getCollections(userId: userId), !localCollections.isEmpty {
            completion(.success(localCollections))
            
            // 2. Actualizar desde API en background
            apiService.getUserCollections(userId: userId) { [weak self] result in
                if case .success(let remoteCollections) = result {
                    self?.coreDataManager.saveCollections(remoteCollections)
                }
            }
            return
        }
        
        // 3. Si no hay cache, cargar desde API
        apiService.getUserCollections(userId: userId) { [weak self] result in
            switch result {
            case .success(let collections):
                self?.coreDataManager.saveCollections(collections)
                completion(.success(collections))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

enum ValidationError: Error {
    case emptyName
    case invalidURL
}
```

---

## ☁️ Infraestructura AWS Necesaria

### 1. AWS Cognito (Autenticación)

**Configuración:**
- User Pool para usuarios
- Identity Pool para acceso a recursos AWS
- Federated Identity con Google
- Email/Password como método alternativo

**Endpoints necesarios:**
- `/auth/signin` - Login
- `/auth/signup` - Registro
- `/auth/signout` - Logout
- `/auth/refresh` - Refresh token

### 2. API Gateway (REST API)

**Endpoints propuestos:**
```
POST   /collections              - Crear colección
GET    /users/{userId}/collections - Obtener colecciones
GET    /collections/{id}         - Obtener colección específica
PUT    /collections/{id}          - Actualizar colección
DELETE /collections/{id}          - Eliminar colección

POST   /collections/{id}/paintings - Agregar pintura
DELETE /paintings/{id}            - Eliminar pintura
```

### 3. Lambda Functions

**Funciones necesarias:**
- `createCollection` - Crear colección en DynamoDB
- `getUserCollections` - Obtener colecciones de usuario
- `updateCollection` - Actualizar colección
- `deleteCollection` - Eliminar colección
- `addPainting` - Agregar pintura a colección

### 4. DynamoDB (Estructura de Tablas)

**Tabla: `collections`**
```
Partition Key: userId (String)
Sort Key: collectionId (String)
Attributes:
  - name (String)
  - thumbnailURL (String, optional)
  - createdAt (Number - timestamp)
  - updatedAt (Number - timestamp)
```

**Tabla: `paintings`**
```
Partition Key: collectionId (String)
Sort Key: paintingId (String)
Attributes:
  - name (String)
  - videoURL (String)
  - imageTrackerName (String)
  - order (Number)
  - createdAt (Number - timestamp)
```

### 5. S3 (Almacenamiento)

**Buckets:**
- `neon-caron-image-trackers` - Imágenes para AR trackers
- `neon-caron-thumbnails` - Thumbnails de colecciones

---

## 🔐 Seguridad y Autenticación

### Flujo de Autenticación:

```
1. Usuario se autentica con Cognito
   ↓
2. Cognito retorna tokens (Access Token, ID Token, Refresh Token)
   ↓
3. iOS guarda tokens localmente (Keychain)
   ↓
4. Cada request a API Gateway incluye Access Token en header
   ↓
5. Lambda valida token con Cognito
   ↓
6. Si válido, procesa request
```

### Headers en cada request:
```swift
headers = [
    "Authorization": "Bearer <access_token>",
    "Content-Type": "application/json"
]
```

---

## 📊 Comparación: Firebase vs AWS

| Aspecto | Firebase | AWS |
|---------|----------|-----|
| **Conexión** | SDK directo | HTTP REST API |
| **Autenticación** | Firebase Auth | Cognito |
| **Base de Datos** | Firestore | DynamoDB |
| **Storage** | Firebase Storage | S3 |
| **Backend** | No necesario | Lambda Functions |
| **Complejidad** | Baja | Media-Alta |
| **Control** | Limitado | Total |
| **Costo** | Pay-as-you-go | Pay-as-you-go |
| **Escalabilidad** | Automática | Automática |

---

## 🎯 Ventajas de AWS + DynamoDB

### ✅ **Ventajas:**
1. **Control total** sobre infraestructura
2. **Escalable** automáticamente
3. **Integración** con otros servicios AWS
4. **Costo eficiente** (serverless)
5. **Seguridad** robusta con IAM y Cognito
6. **Flexibilidad** para lógica compleja en Lambda

### ⚠️ **Consideraciones:**
1. **Más complejo** que Firebase
2. **Requiere API** (API Gateway + Lambda)
3. **Más configuración** inicial
4. **Manejo manual** de tokens y refresh

---

## 📋 Checklist de Implementación

### Fase Backend (AWS):
- [ ] Configurar AWS Cognito User Pool
- [ ] Configurar Cognito Identity Pool
- [ ] Crear tablas en DynamoDB
- [ ] Crear Lambda Functions
- [ ] Configurar API Gateway
- [ ] Configurar S3 buckets
- [ ] Configurar IAM roles y políticas
- [ ] Implementar autenticación en Lambda

### Fase iOS:
- [ ] Agregar AWS SDK al proyecto
- [ ] Implementar CognitoService
- [ ] Implementar APIService
- [ ] Implementar CollectionRepository
- [ ] Implementar CoreDataManager
- [ ] Actualizar LoginViewController
- [ ] Crear CreateCollectionViewController

---

## 🚀 Próximos Pasos

1. **Configurar AWS Cognito** - Autenticación
2. **Crear API Gateway + Lambda** - Backend
3. **Configurar DynamoDB** - Base de datos
4. **Implementar APIService en iOS** - HTTP calls
5. **Implementar Repository Pattern** - Separar lógica

¿Quieres que actualice el plan de desarrollo para reflejar esta arquitectura AWS? 🎯
