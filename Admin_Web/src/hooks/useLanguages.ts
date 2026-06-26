import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { languagesApi } from '../api/reference.api';
import type { CreateReferenceItem, UpdateReferenceItem } from '../types/reference.types';

export function useLanguages() {
  return useQuery({
    queryKey: ['languages'],
    queryFn: () => languagesApi.list(),
  });
}

export function useCreateLanguage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateReferenceItem) => languagesApi.create(data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['languages'] }),
  });
}

export function useUpdateLanguage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateReferenceItem }) =>
      languagesApi.update(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['languages'] }),
  });
}

export function useDeactivateLanguage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => languagesApi.deactivate(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['languages'] }),
  });
}
