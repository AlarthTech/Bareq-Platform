import { useMemo, useRef, useState } from 'react';
import { useAllUsers } from '../../../hooks/useAllUsers';
import type { AppUser } from '../../../types/api.types';

function isCustomer(user: AppUser): boolean {
  return user.userTypeName.toLowerCase() === 'customer';
}

interface CustomerSelectProps {
  value: AppUser | null;
  onChange: (customer: AppUser | null) => void;
  placeholder?: string;
}

export function CustomerSelect({
  value,
  onChange,
  placeholder = 'ابحث بالاسم أو الهاتف',
}: CustomerSelectProps) {
  const [query, setQuery] = useState(value?.fullName ?? '');
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const { data: users = [], isLoading } = useAllUsers();

  const customers = useMemo(() => users.filter(isCustomer), [users]);

  const matches = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return customers.slice(0, 8);
    return customers
      .filter(
        (c) =>
          c.phone.includes(q) ||
          c.fullName.toLowerCase().includes(q) ||
          c.email.toLowerCase().includes(q) ||
          String(c.id).includes(q)
      )
      .slice(0, 8);
  }, [customers, query]);

  const pick = (customer: AppUser) => {
    onChange(customer);
    setQuery(customer.fullName);
    setOpen(false);
  };

  return (
    <div ref={containerRef} className="relative">
      <input
        type="search"
        value={query}
        onChange={(e) => {
          setQuery(e.target.value);
          onChange(null);
          setOpen(true);
        }}
        onFocus={() => setOpen(true)}
        onBlur={() => window.setTimeout(() => setOpen(false), 150)}
        placeholder={placeholder}
        className="w-full border border-gray-200 rounded-lg px-3 py-2"
        autoComplete="off"
      />
      {value && (
        <p className="text-xs text-bareq-600 mt-1">
          #{value.id} — {value.phone}
        </p>
      )}
      {open && matches.length > 0 && (
        <ul className="absolute z-20 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-48 overflow-y-auto">
          {isLoading && (
            <li className="px-3 py-2 text-sm text-gray-500">جاري التحميل...</li>
          )}
          {matches.map((c) => (
            <li key={c.id}>
              <button
                type="button"
                className="w-full text-right px-3 py-2 text-sm hover:bg-bareq-50"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => pick(c)}
              >
                <span className="font-medium">{c.fullName}</span>
                <span className="text-gray-500 mr-2">{c.phone}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export function useCustomers() {
  const { data: users = [] } = useAllUsers();
  return useMemo(() => users.filter(isCustomer), [users]);
}
