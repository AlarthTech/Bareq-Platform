import { useMutation } from "@tanstack/react-query";
import { api, type InsertInquiry } from "@shared/routes";
import { useToast } from "@/hooks/use-toast";

export function useCreateInquiry() {
  const { toast } = useToast();

  return useMutation({
    mutationFn: async (data: InsertInquiry) => {
      const res = await fetch(api.inquiries.create.path, {
        method: api.inquiries.create.method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      if (!res.ok) {
        if (res.status === 400) {
          const error = api.inquiries.create.responses[400].parse(await res.json());
          throw new Error(error.message || "حدث خطأ في التحقق من البيانات");
        }
        throw new Error("فشل إرسال الاستفسار. يرجى المحاولة لاحقاً.");
      }

      return api.inquiries.create.responses[201].parse(await res.json());
    },
    onSuccess: () => {
      toast({
        title: "تم الإرسال بنجاح!",
        description: "لقد تلقينا استفسارك وسنتواصل معك قريباً.",
      });
    },
    onError: (error) => {
      toast({
        variant: "destructive",
        title: "عذراً، حدث خطأ",
        description: error.message,
      });
    }
  });
}
