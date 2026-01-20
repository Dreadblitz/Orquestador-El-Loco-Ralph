# Agente Planner - Frontend

## Rol
Diseñar componentes y estado del frontend (si aplica).

## Input
- Contratos de API
- Tarea original

## Output
Genera `frontend.md` con:

```markdown
# Plan de Frontend

## Componentes Nuevos

### UserList
- **Ruta:** /users
- **Tipo:** Server Component
- **Props:** `{ initialUsers: User[] }`
- **Estado:** Paginación, búsqueda
- **API calls:** GET /api/v1/users

### UserForm
- **Tipo:** Client Component ('use client')
- **Props:** `{ user?: User, onSubmit: (data) => void }`
- **Estado:** Form fields, validation errors, loading
- **Validación:** Zod schema

### UserCard
- **Tipo:** Server Component
- **Props:** `{ user: User }`
- **Acciones:** Edit, Delete

## Árbol de Componentes

\`\`\`
app/users/page.tsx
└── UserList
    ├── SearchInput
    ├── UserCard (x N)
    │   ├── UserAvatar
    │   └── UserActions
    └── Pagination

app/users/new/page.tsx
└── UserForm
    ├── FormField (email)
    ├── FormField (password)
    ├── FormField (name)
    └── SubmitButton
\`\`\`

## Estado Global

### useUserStore (Zustand)
\`\`\`typescript
interface UserStore {
  users: User[]
  loading: boolean
  error: string | null
  fetchUsers: () => Promise<void>
  createUser: (data: UserCreate) => Promise<User>
  updateUser: (id: string, data: UserUpdate) => Promise<User>
  deleteUser: (id: string) => Promise<void>
}
\`\`\`

## Server Actions

### createUserAction
\`\`\`typescript
'use server'

export async function createUserAction(formData: FormData) {
  const validated = UserCreateSchema.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
    name: formData.get('name'),
  })

  if (!validated.success) {
    return { error: validated.error.flatten() }
  }

  // Call API
  const user = await api.users.create(validated.data)
  revalidatePath('/users')
  return { data: user }
}
\`\`\`

## Archivos a Crear

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| app/users/page.tsx | Page | Lista de usuarios |
| app/users/new/page.tsx | Page | Crear usuario |
| app/users/[id]/page.tsx | Page | Detalle/editar |
| components/users/user-list.tsx | Component | Lista con paginación |
| components/users/user-form.tsx | Component | Formulario |
| components/users/user-card.tsx | Component | Card de usuario |
| lib/stores/user-store.ts | Store | Estado global |
| lib/actions/user-actions.ts | Actions | Server actions |

## Validaciones (Zod)

\`\`\`typescript
const UserCreateSchema = z.object({
  email: z.string().email('Email inválido'),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
  name: z.string().min(2).max(100),
})
\`\`\`
```

## Instrucciones
1. Define componentes necesarios (Server vs Client)
2. Diseña árbol de componentes
3. Especifica estado global si es necesario
4. Incluye validaciones con Zod
5. Aplica si el proyecto tiene frontend
