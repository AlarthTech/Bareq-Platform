import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api, buildUrl } from "@shared/routes";
import { type Cleaner, type InsertCleaner } from "@shared/schema";
import { useToast } from "@/hooks/use-toast";

export function useCleaners() {
  return useQuery<Cleaner[]>({
    queryKey: [api.cleaners.list.path],
    queryFn: async () => {
      const res = await fetch(api.cleaners.list.path, { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch cleaners");
      return res.json();
    },
  });
}

export function useCleaner(id: number) {
  return useQuery<Cleaner>({
    queryKey: [api.cleaners.get.path, id],
    queryFn: async () => {
      const url = buildUrl(api.cleaners.get.path, { id });
      const res = await fetch(url, { credentials: "include" });
      if (res.status === 404) throw new Error("Cleaner not found");
      if (!res.ok) throw new Error("Failed to fetch cleaner");
      return res.json();
    },
    enabled: !!id,
  });
}

export function useCreateCleaner() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: InsertCleaner) => {
      const res = await fetch(api.cleaners.create.path, {
        method: api.cleaners.create.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
        credentials: "include",
      });
      if (!res.ok) throw new Error("Failed to add cleaner");
      return res.json() as Promise<Cleaner>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.cleaners.list.path] });
      toast({ title: "تم إضافة العاملة بنجاح" });
    },
    onError: (err) => {
      toast({ variant: "destructive", title: "خطأ", description: err.message });
    }
  });
}
