import { useQuery } from '@tanstack/react-query';
import { usersApi } from '../api/users.api';

export function useAllUsers() {
  return useQuery({
    queryKey: ['users', 'all'],
    queryFn: usersApi.fetchAll,
  });
}
