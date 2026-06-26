# Admin Dashboard — Cities, Nationalities, Languages CRUD Implementation

Copy everything below the line into your Admin Dashboard front-end agent.

**Base URL:** `http://102.203.200.55:5545`  
**Auth (Create/Update/Delete):** `Authorization: Bearer {adminToken}`

---

## PROMPT START

Implement three **Reference Data** CRUD modules in the Bareq Admin Dashboard:

1. **Cities** — full CRUD + **pagination**
2. **Nationalities** — Create / Read / Update only (**no DELETE endpoint**)
3. **Languages** — Create / Read / Update only (**no DELETE endpoint**)

All three share the same entity shape. Use a reusable pattern but respect API differences.

---

## Shared entity shape

```typescript
interface ReferenceItem {
  id: number;
  name: string;
  code?: string | null;
  isActive: boolean;
}

interface CreateReferenceItem {
  name: string;          // required, max 100
  code?: string | null;  // optional, max 10
  isActive?: boolean;    // default true
}

interface UpdateReferenceItem {
  name?: string;
  code?: string | null;
  isActive?: boolean;
}
```

**Form validation (Zod example):**

```typescript
const createSchema = z.object({
  name: z.string().min(1, 'الاسم مطلوب').max(100),
  code: z.string().max(10).optional().nullable(),
  isActive: z.boolean().default(true),
});

const updateSchema = createSchema.partial();
```

---

## 1. Cities CRUD

### Endpoints summary

| Action | Method | Path | Auth |
|--------|--------|------|------|
| List | GET | `/api/Cities/GetAllCities?page=1&pageSize=20` | Anonymous |
| Get one | GET | `/api/Cities/GetCityById/{id}` | Anonymous |
| Create | POST | `/api/Cities/CreateCity` | **Admin** |
| Update | PATCH | `/api/Cities/UpdateCity/{id}` | **Admin** |
| Delete | DELETE | `/api/Cities/DeleteCity/{id}` | **Admin** (soft delete) |

### List — paginated

```http
GET /api/Cities/GetAllCities?page=1&pageSize=20
```

**Response:** `PagedResult<CityDTO>`

```json
{
  "items": [
    { "id": 1, "name": "طرابلس", "code": "TIP", "isActive": true }
  ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 5,
  "totalPages": 1,
  "hasNextPage": false,
  "hasPreviousPage": false
}
```

> List returns **active cities only** (`isActive = true`).

### Get by ID

```http
GET /api/Cities/GetCityById/1
```

**404** if not found or inactive.

### Create

```http
POST /api/Cities/CreateCity
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "name": "طرابلس",
  "code": "TIP",
  "isActive": true
}
```

**Success (201):** returns created `CityDTO` in body.

### Update

```http
PATCH /api/Cities/UpdateCity/1
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "name": "طرابلس الكبرى",
  "code": "TIP",
  "isActive": true
}
```

Send only changed fields. **Success: 204** (no body).

**404** if city not found or already inactive.

### Delete (soft)

```http
DELETE /api/Cities/DeleteCity/1
Authorization: Bearer {token}
```

Sets `isActive = false`. **Success: 204**.

---

## 2. Nationalities CRUD

### Endpoints summary

| Action | Method | Path | Auth |
|--------|--------|------|------|
| List | GET | `/api/Nationalities/GetNationalities` | Anonymous |
| Get one | GET | `/api/Nationalities/GetNationalityById/{id}` | Anonymous |
| Create | POST | `/api/Nationalities/CreateNationality` | **Admin** |
| Update | PATCH | `/api/Nationalities/UpdateNationality/{id}` | **Admin** |
| Delete | — | **NOT IMPLEMENTED** | — |

### List — full array (NOT paginated)

```http
GET /api/Nationalities/GetNationalities
```

**Response:** root array

```json
[
  { "id": 1, "name": "ليبية", "code": "LY", "isActive": true },
  { "id": 2, "name": "فلبينية", "code": "PH", "isActive": true }
]
```

> Returns **active only**. For admin table with inactive items, you only see active unless you track locally after deactivate.

### Get by ID

```http
GET /api/Nationalities/GetNationalityById/1
```

Returns item even if inactive (no `IsActive` filter on single get).

### Create

```http
POST /api/Nationalities/CreateNationality
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "name": "ليبية",
  "code": "LY",
  "isActive": true
}
```

**Success (201):** returns `NationalityDTO`.

### Update

```http
PATCH /api/Nationalities/UpdateNationality/1
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "name": "ليبي",
  "code": "LY",
  "isActive": false
}
```

**Success: 204**.

### “Delete” workaround

There is **no DELETE endpoint**. To deactivate:

```http
PATCH /api/Nationalities/UpdateNationality/1
{ "isActive": false }
```

UI: show **"تعطيل"** instead of "حذف". Item disappears from public list after deactivate.

---

## 3. Languages CRUD

Same pattern as Nationalities.

### Endpoints summary

| Action | Method | Path | Auth |
|--------|--------|------|------|
| List | GET | `/api/Languages/GetAllLanguages` | Anonymous |
| Get one | GET | `/api/Languages/GetLanguageById/{id}` | Anonymous |
| Create | POST | `/api/Languages/CreateLanguage` | **Admin** |
| Update | PATCH | `/api/Languages/UpdateLanguage/{id}` | **Admin** |
| Delete | — | **NOT IMPLEMENTED** | — |

### List — full array

```http
GET /api/Languages/GetAllLanguages
```

```json
[
  { "id": 1, "name": "العربية", "code": "AR", "isActive": true },
  { "id": 2, "name": "English", "code": "EN", "isActive": true }
]
```

### Create

```http
POST /api/Languages/CreateLanguage
```

```json
{ "name": "العربية", "code": "AR", "isActive": true }
```

### Update / Deactivate

```http
PATCH /api/Languages/UpdateLanguage/1
{ "isActive": false }
```

---

## 4. API service layer (TypeScript)

```typescript
// api/reference.api.ts
import { api } from './client';
import type { PagedResult, ReferenceItem, CreateReferenceItem, UpdateReferenceItem } from '../types';

// ─── Cities (paginated) ───
export const citiesApi = {
  list: (page = 1, pageSize = 20) =>
    api.get<PagedResult<ReferenceItem>>('/api/Cities/GetAllCities', {
      params: { page, pageSize },
    }),

  getById: (id: number) =>
    api.get<ReferenceItem>(`/api/Cities/GetCityById/${id}`),

  create: (data: CreateReferenceItem) =>
    api.post<ReferenceItem>('/api/Cities/CreateCity', data),

  update: (id: number, data: UpdateReferenceItem) =>
    api.patch(`/api/Cities/UpdateCity/${id}`, data),

  remove: (id: number) =>
    api.delete(`/api/Cities/DeleteCity/${id}`),
};

// ─── Nationalities (array) ───
export const nationalitiesApi = {
  list: () =>
    api.get<ReferenceItem[]>('/api/Nationalities/GetNationalities'),

  getById: (id: number) =>
    api.get<ReferenceItem>(`/api/Nationalities/GetNationalityById/${id}`),

  create: (data: CreateReferenceItem) =>
    api.post<ReferenceItem>('/api/Nationalities/CreateNationality', data),

  update: (id: number, data: UpdateReferenceItem) =>
    api.patch(`/api/Nationalities/UpdateNationality/${id}`, data),

  deactivate: (id: number) =>
    api.patch(`/api/Nationalities/UpdateNationality/${id}`, { isActive: false }),
};

// ─── Languages (array) ───
export const languagesApi = {
  list: () =>
    api.get<ReferenceItem[]>('/api/Languages/GetAllLanguages'),

  getById: (id: number) =>
    api.get<ReferenceItem>(`/api/Languages/GetLanguageById/${id}`),

  create: (data: CreateReferenceItem) =>
    api.post<ReferenceItem>('/api/Languages/CreateLanguage', data),

  update: (id: number, data: UpdateReferenceItem) =>
    api.patch(`/api/Languages/UpdateLanguage/${id}`, data),

  deactivate: (id: number) =>
    api.patch(`/api/Languages/UpdateLanguage/${id}`, { isActive: false }),
};
```

---

## 5. TanStack Query hooks

```typescript
// hooks/useCities.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { citiesApi } from '../api/reference.api';

export function useCities(page: number, pageSize = 20) {
  return useQuery({
    queryKey: ['cities', page, pageSize],
    queryFn: () => citiesApi.list(page, pageSize).then(r => r.data),
  });
}

export function useCreateCity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: citiesApi.create,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cities'] }),
  });
}

export function useUpdateCity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateReferenceItem }) =>
      citiesApi.update(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cities'] }),
  });
}

export function useDeleteCity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: citiesApi.remove,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['cities'] }),
  });
}
```

```typescript
// hooks/useNationalities.ts — same pattern, no pagination
export function useNationalities() {
  return useQuery({
    queryKey: ['nationalities'],
    queryFn: () => nationalitiesApi.list().then(r => r.data),
  });
}
// useCreateNationality, useUpdateNationality, useDeactivateNationality — same as cities
```

Repeat for `useLanguages`.

---

## 6. Reusable UI components

### ReferenceDataPage (generic list + CRUD)

Build one reusable page component parameterized by resource type:

```typescript
type ResourceConfig = {
  title: string;           // e.g. "المدن"
  route: string;           // e.g. "/reference/cities"
  paginated: boolean;
  canDelete: boolean;      // true for cities only
  useList: () => ReturnType<typeof useCities>; // or useNationalities
  // ... mutation hooks
};
```

### Table columns (Arabic RTL)

| العمود | Field |
|--------|-------|
| # | `id` |
| الاسم | `name` |
| الرمز | `code` |
| الحالة | `isActive` → badge نشط / معطل |
| إجراءات | Edit, Delete/Deactivate |

### Create/Edit modal form

Fields:

| Label | Input | Required |
|-------|-------|----------|
| الاسم | text | Yes |
| الرمز | text (max 10) | No |
| نشط | toggle switch | No (default on) |

Buttons: **حفظ** · **إلغاء**

### Confirm dialogs

- Cities delete: **"هل تريد حذف هذه المدينة؟"** → calls DELETE
- Nationalities/Languages deactivate: **"هل تريد تعطيل هذه الجنسية؟"** → PATCH `{ isActive: false }`

---

## 7. Page routes

```
/reference/cities          → CitiesListPage (paginated table)
/reference/nationalities   → NationalitiesListPage (full table)
/reference/languages       → LanguagesListPage (full table)
```

Sidebar under **"البيانات المرجعية"**:

- المدن
- الجنسيات
- اللغات

---

## 8. Cities list page (with pagination)

```tsx
function CitiesPage() {
  const [page, setPage] = useState(1);
  const { data, isLoading } = useCities(page);
  const createCity = useCreateCity();
  const deleteCity = useDeleteCity();

  return (
    <ReferenceLayout title="المدن">
      <Button onClick={() => setModalOpen(true)}>+ إضافة مدينة</Button>

      <DataTable
        columns={columns}
        rows={data?.items ?? []}
        loading={isLoading}
      />

      <Pagination
        page={data?.page ?? 1}
        totalPages={data?.totalPages ?? 1}
        hasNext={data?.hasNextPage}
        hasPrev={data?.hasPreviousPage}
        onPageChange={setPage}
      />

      <ReferenceFormModal
        open={modalOpen}
        onSubmit={(values) => createCity.mutateAsync(values)}
      />
    </ReferenceLayout>
  );
}
```

---

## 9. Nationalities / Languages list page (no pagination)

```tsx
function NationalitiesPage() {
  const { data = [], isLoading } = useNationalities();
  const deactivate = useDeactivateNationality();

  // Client-side search optional
  const [search, setSearch] = useState('');
  const filtered = data.filter(n =>
    n.name.includes(search) || n.code?.includes(search)
  );

  return (
    <ReferenceLayout title="الجنسيات">
      <SearchInput value={search} onChange={setSearch} placeholder="بحث..." />
      <Button onClick={() => setModalOpen(true)}>+ إضافة جنسية</Button>

      <DataTable columns={columns} rows={filtered} loading={isLoading} />

      {/* No Pagination component — full list from API */}
    </ReferenceLayout>
  );
}
```

---

## 10. Error handling

| Status | Display |
|--------|---------|
| 400 | Validation errors from `ModelState` or Arabic string |
| 401 | Redirect to login |
| 403 | "لا تملك صلاحية — Admin فقط" |
| 404 | "العنصر غير موجود" |
| 204 | Toast "تم الحفظ بنجاح" |

```typescript
function getErrorMessage(err: unknown): string {
  if (axios.isAxiosError(err)) {
    const data = err.response?.data;
    if (typeof data === 'string') return data;
    if (data?.message) return data.message;
    if (data?.errors) return Object.values(data.errors).flat().join(', ');
  }
  return 'حدث خطأ غير متوقع';
}
```

---

## 11. Comparison table (implement correctly)

| Feature | Cities | Nationalities | Languages |
|---------|--------|---------------|-----------|
| List endpoint | `GetAllCities` | `GetNationalities` | `GetAllLanguages` |
| Pagination | ✅ `PagedResult` | ❌ full array | ❌ full array |
| Create | `CreateCity` | `CreateNationality` | `CreateLanguage` |
| Update | `UpdateCity/{id}` | `UpdateNationality/{id}` | `UpdateLanguage/{id}` |
| Delete | ✅ `DeleteCity/{id}` soft | ❌ use `isActive: false` | ❌ use `isActive: false` |
| List filters active only | Yes | Yes | Yes |
| Admin JWT for writes | Yes | Yes | Yes |

---

## 12. Testing checklist

### Cities
- [ ] List with pagination (page 1, 2)
- [ ] Create city with name + code
- [ ] Edit city name
- [ ] Delete city → disappears from list
- [ ] 403 without Admin token on create

### Nationalities
- [ ] List loads full array
- [ ] Create nationality
- [ ] Edit name/code
- [ ] Deactivate → disappears from list
- [ ] Client-side search works

### Languages
- [ ] Same as nationalities
- [ ] Used later in worker form as multi-select (`languagesIds: "1,2,3"`)

---

## 13. curl examples (manual QA)

```bash
TOKEN="your-admin-jwt"
BASE="http://102.203.200.55:5545"

# Cities
curl -sS "$BASE/api/Cities/GetAllCities?page=1&pageSize=10"
curl -sS -X POST "$BASE/api/Cities/CreateCity" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"بنغازي","code":"BEN","isActive":true}'
curl -sS -X PATCH "$BASE/api/Cities/UpdateCity/2" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"بنغازي"}'
curl -sS -X DELETE "$BASE/api/Cities/DeleteCity/2" \
  -H "Authorization: Bearer $TOKEN"

# Nationalities
curl -sS "$BASE/api/Nationalities/GetNationalities"
curl -sS -X POST "$BASE/api/Nationalities/CreateNationality" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"مصرية","code":"EG","isActive":true}'

# Languages
curl -sS "$BASE/api/Languages/GetAllLanguages"
curl -sS -X POST "$BASE/api/Languages/CreateLanguage" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"Français","code":"FR","isActive":true}'
```

---

## PROMPT END
