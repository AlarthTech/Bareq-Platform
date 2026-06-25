import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api, buildUrl } from "@shared/routes";
import { type Booking, type InsertBooking } from "@shared/schema";
import { useToast } from "@/hooks/use-toast";

export function useBookings() {
  return useQuery<Booking[]>({
    queryKey: [api.bookings.list.path],
    queryFn: async () => {
      const res = await fetch(api.bookings.list.path, { credentials: "include" });
      if (!res.ok) throw new Error("Failed to fetch bookings");
      return res.json();
    },
  });
}

export function useCreateBooking() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: InsertBooking) => {
      const res = await fetch(api.bookings.create.path, {
        method: api.bookings.create.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
        credentials: "include",
      });
      
      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.message || "Failed to create booking");
      }
      return res.json() as Promise<Booking>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.bookings.list.path] });
      toast({ title: "تم الحجز بنجاح", description: "سنقوم بالتواصل معك قريباً لتأكيد الموعد" });
    },
    onError: (err) => {
      toast({ variant: "destructive", title: "فشل الحجز", description: err.message });
    }
  });
}

export function useUpdateBookingStatus() {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  return useMutation({
    mutationFn: async ({ id, status }: { id: number; status: string }) => {
      const url = buildUrl(api.bookings.updateStatus.path, { id });
      const res = await fetch(url, {
        method: api.bookings.updateStatus.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status }),
        credentials: "include",
      });
      
      if (!res.ok) throw new Error("Failed to update status");
      return res.json() as Promise<Booking>;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [api.bookings.list.path] });
      toast({ title: "تم تحديث حالة الحجز" });
    },
    onError: (err) => {
      toast({ variant: "destructive", title: "خطأ", description: err.message });
    }
  });
}
