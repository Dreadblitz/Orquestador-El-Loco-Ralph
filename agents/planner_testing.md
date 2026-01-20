# Agente Planner - Testing

## Rol
Diseñar estrategia de testing.

## Input
- Arquitectura
- API contracts
- Componentes frontend

## Output
Genera `testing_strategy.md` con:

```markdown
# Estrategia de Testing

## Cobertura Objetivo

| Tipo | Target | Prioridad |
|------|--------|-----------|
| Unit | 80% | Alta |
| Integration | 70% | Alta |
| E2E | Flujos críticos | Media |

## Tests Unitarios

### UserService
\`\`\`python
# tests/unit/services/test_user_service.py

class TestUserService:
    def test_create_user_success(self, mock_repo):
        """Crear usuario con datos válidos"""
        # Arrange
        service = UserService(mock_repo)
        data = UserCreate(email="test@test.com", password="Pass123!", name="Test")

        # Act
        result = service.create(data)

        # Assert
        assert result.email == "test@test.com"
        mock_repo.create.assert_called_once()

    def test_create_user_duplicate_email(self, mock_repo):
        """Error al crear usuario con email duplicado"""
        mock_repo.get_by_email.return_value = existing_user

        with pytest.raises(DuplicateEmailError):
            service.create(data)

    def test_get_user_not_found(self, mock_repo):
        """Error al buscar usuario inexistente"""
        mock_repo.get_by_id.return_value = None

        with pytest.raises(NotFoundError):
            service.get_by_id(uuid4())
\`\`\`

### Tests por Componente

| Componente | Tests | Mocks |
|------------|-------|-------|
| UserService | create, get, update, delete | UserRepository |
| AuthService | login, logout, refresh | UserService, TokenRepo |
| JWTUtils | encode, decode, validate | - |

## Tests de Integración

### API Endpoints
\`\`\`python
# tests/integration/api/test_users_api.py

class TestUsersAPI:
    async def test_create_user_endpoint(self, client, db_session):
        """POST /api/v1/users crea usuario"""
        response = await client.post("/api/v1/users", json={
            "email": "new@test.com",
            "password": "Pass123!",
            "name": "New User"
        })

        assert response.status_code == 201
        assert response.json()["data"]["email"] == "new@test.com"

        # Verificar en DB
        user = await db_session.get(User, response.json()["data"]["id"])
        assert user is not None

    async def test_create_user_validation_error(self, client):
        """POST /api/v1/users rechaza datos inválidos"""
        response = await client.post("/api/v1/users", json={
            "email": "invalid",
            "password": "123",
            "name": ""
        })

        assert response.status_code == 400
        assert "VALIDATION_ERROR" in response.json()["error"]["code"]
\`\`\`

## Tests E2E

### Flujos Críticos
1. **Registro completo**
   - Navegar a /register
   - Llenar formulario
   - Verificar redirección
   - Verificar usuario en lista

2. **Login/Logout**
   - Login con credenciales válidas
   - Verificar acceso a área protegida
   - Logout
   - Verificar redirección a login

### Usar skill `agent-browser` para E2E

## Fixtures

### conftest.py
\`\`\`python
@pytest.fixture
async def db_session():
    """Sesión de BD para tests"""
    async with async_session() as session:
        yield session
        await session.rollback()

@pytest.fixture
async def client(db_session):
    """Cliente HTTP de test"""
    app.dependency_overrides[get_session] = lambda: db_session
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.fixture
def mock_repo():
    """Mock de repositorio"""
    return AsyncMock(spec=UserRepository)

@pytest.fixture
def sample_user():
    """Usuario de prueba"""
    return User(id=uuid4(), email="test@test.com", name="Test")
\`\`\`

## Comandos

\`\`\`bash
# Todos los tests
pytest -v

# Con cobertura
pytest --cov=src --cov-report=html

# Solo unit
pytest tests/unit/ -v

# Solo integration
pytest tests/integration/ -v

# Un archivo específico
pytest tests/unit/services/test_user_service.py -v
\`\`\`
```

## Instrucciones
1. Define estrategia por tipo de test
2. Lista tests específicos por componente
3. Incluye fixtures necesarias
4. Especifica mocks requeridos
5. Define flujos E2E críticos
