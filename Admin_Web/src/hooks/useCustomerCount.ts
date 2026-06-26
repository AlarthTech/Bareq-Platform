import { useQuery } from '@tanstack/react-query';
import { usersApi } from '../api/users.api';

function isCustomer(userTypeName: string): boolean {
  return userTypeName.toLowerCase() === 'customer';
}

export function useCustomerCount() {
  return useQuery({
    queryKey: ['users', 'all'],
    queryFn: usersApi.fetchAll,
    select: (users) => users.filter((u) => isCustomer(u.userTypeName)).length,
    staleTime: 60_000,
  });
}
