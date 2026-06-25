import { motion } from "framer-motion";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { insertInquirySchema } from "@shared/schema";
import { useCreateInquiry } from "@/hooks/use-inquiries";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form";
import { MessageSquare, Send } from "lucide-react";

type FormValues = z.infer<typeof insertInquirySchema>;

export function Contact() {
  const mutation = useCreateInquiry();
  
  const form = useForm<FormValues>({
    resolver: zodResolver(insertInquirySchema),
    defaultValues: {
      name: "",
      email: "",
      message: "",
    },
  });

  const onSubmit = (data: FormValues) => {
    mutation.mutate(data, {
      onSuccess: () => form.reset()
    });
  };

  return (
    <section id="contact" className="py-24 bg-white relative overflow-hidden">
      {/* Decorative Blob */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none z-0">
        <div className="absolute top-[-10%] right-[-5%] w-[40%] h-[60%] rounded-full bg-primary/5 blur-[120px]" />
        <div className="absolute bottom-[-10%] left-[-5%] w-[50%] h-[50%] rounded-full bg-accent/30 blur-[100px]" />
      </div>

      <div className="container mx-auto px-4 md:px-6 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary/10 text-primary font-medium text-sm mb-6">
              <MessageSquare className="w-4 h-4" />
              <span>تواصل معنا</span>
            </div>
            
            <h2 className="text-3xl md:text-5xl font-bold font-display mb-6">
              تواصل معنا لأي استفسار
            </h2>
            
            <p className="text-lg text-muted-foreground leading-relaxed mb-8">
              هل أنت شركة ترغب في الانضمام للمنصة؟ أو عميل لديه استفسار؟ املأ النموذج وسيقوم فريقنا بالتواصل معك في أقرب وقت ممكن.
            </p>

            <div className="bg-primary/5 border border-primary/10 rounded-2xl p-6 mb-8">
              <h4 className="font-bold text-foreground mb-2">نحن متاحون على مدار الساعة</h4>
              <p className="text-muted-foreground text-sm">خدمة العملاء: متوفرة طوال أيام الأسبوع</p>
              <p className="text-muted-foreground text-sm">الدعم الفني: 24/7</p>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="bg-card rounded-3xl p-8 md:p-10 shadow-2xl shadow-primary/10 border border-border"
          >
            <h3 className="text-2xl font-bold font-display mb-6 text-foreground">أرسل رسالة</h3>
            
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
                <FormField
                  control={form.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-foreground">الاسم الكريم</FormLabel>
                      <FormControl>
                        <Input 
                          placeholder="أدخل اسمك هنا" 
                          className="rounded-xl bg-background border-border/80 focus-visible:ring-primary focus-visible:border-primary h-12" 
                          {...field} 
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="email"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-foreground">البريد الإلكتروني أو رقم الهاتف</FormLabel>
                      <FormControl>
                        <Input 
                          placeholder="example@mail.com" 
                          className="rounded-xl bg-background border-border/80 focus-visible:ring-primary focus-visible:border-primary h-12" 
                          dir="ltr"
                          {...field} 
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                
                <FormField
                  control={form.control}
                  name="message"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-foreground">رسالتك</FormLabel>
                      <FormControl>
                        <Textarea 
                          placeholder="كيف يمكننا مساعدتك؟" 
                          className="rounded-xl bg-background border-border/80 focus-visible:ring-primary focus-visible:border-primary min-h-[120px] resize-none" 
                          {...field} 
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <Button 
                  type="submit" 
                  className="w-full rounded-xl h-12 text-lg shadow-lg shadow-primary/25 hover:shadow-xl hover:-translate-y-0.5 transition-all flex items-center gap-2"
                  disabled={mutation.isPending}
                >
                  {mutation.isPending ? "جاري الإرسال..." : (
                    <>
                      <span>إرسال الرسالة</span>
                      <Send className="w-5 h-5 rtl:-scale-x-100" />
                    </>
                  )}
                </Button>
              </form>
            </Form>
          </motion.div>
          
        </div>
      </div>
    </section>
  );
}
