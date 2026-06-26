import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { nationalitiesApi } from '../api/reference.api';
import type { CreateReferenceItem, UpdateReferenceItem } from '../types/reference.types';

export function useNationalities() {
  return useQuery({
    queryKey: ['nationalities'],
    queryFn: () => nationalitiesApi.list(),
  });
}

export function useCreateNationality() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateReferenceItem) => nationalitiesApi.create(data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['nationalities'] }),
  });
}

export function useUpdateNationality() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateReferenceItem }) =>
      nationalitiesApi.update(id, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['nationalities'] }),
  });
}

export function useDeactivateNationality() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => nationalitiesApi.deactivate(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['nationalities'] }),
  });
}
