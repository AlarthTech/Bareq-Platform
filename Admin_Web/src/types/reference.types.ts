import { z } from 'zod';

export interface ReferenceItem {
  id: number;
  name: string;
  code?: string | null;
  isActive: boolean;
}

export interface CreateReferenceItem {
  name: string;
  code?: string | null;
  isActive?: boolean;
}

export interface UpdateReferenceItem {
  name?: string;
  code?: string | null;
  isActive?: boolean;
}

export const createReferenceSchema = z.object({
  name: z.string().min(1, 'الاسم مطلوب').max(100, '100 حرف كحد أقصى'),
  code: z
    .string()
    .max(10, '10 أحرف كحد أقصى')
    .optional()
    .nullable(),
  isActive: z.boolean(),
});

export const updateReferenceSchema = createReferenceSchema.partial();

export type CreateReferenceForm = z.infer<typeof createReferenceSchema>;
export type UpdateReferenceForm = z.infer<typeof updateReferenceSchema>;

export function toCreatePayload(data: CreateReferenceForm): CreateReferenceItem {
  return {
    name: data.name,
    code: data.code?.trim() ? data.code.trim() : null,
    isActive: data.isActive ?? true,
  };
}

export function toUpdatePayload(data: CreateReferenceForm | UpdateReferenceForm): UpdateReferenceItem {
  return {
    name: data.name,
    code: data.code?.trim() ? data.code.trim() : null,
    isActive: data.isActive,
  };
}
