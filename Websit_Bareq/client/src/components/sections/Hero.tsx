import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { CheckCircle2 } from "lucide-react";
import { LogoMark } from "@/components/brand/Logo";

export function Hero() {
  return (
    <section id="home" className="relative min-h-screen flex items-center pt-20 overflow-hidden">
      {/* Background with subtle shapes */}
      <div className="absolute inset-0 bg-gradient-to-b from-primary/5 to-background z-0" />
      <div className="absolute top-20 right-[-10%] w-[40%] h-[50%] rounded-full bg-primary/10 blur-[100px] z-0" />
      <div className="absolute bottom-10 left-[-10%] w-[30%] h-[40%] rounded-full bg-accent/50 blur-[80px] z-0" />

      <div className="container mx-auto px-4 md:px-6 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Text Content */}
          <motion.div 
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="max-w-2xl"
          >
            <div className="inline-flex items-center gap-2.5 px-3 py-1.5 rounded-full bg-primary/10 text-primary font-medium text-sm mb-6 border border-primary/20">
              <LogoMark size="sm" showGlow={false} className="group" />
              <span>منصة ذكية لربط الشركات والعملاء</span>
            </div>
            
            <h1 className="text-4xl md:text-5xl lg:text-7xl font-bold font-display leading-tight mb-6 text-foreground">
              وجهتك المثالية لخدمات <br/>
              <span className="text-gradient">العمالة المنزلية</span>
            </h1>
            
            <p className="text-lg md:text-xl text-muted-foreground leading-relaxed mb-8">
              منصة البريق تجمع أفضل الشركات وعاملاتها المحترفات في مكان واحد. اختر من بين مئات العاملات المؤهلات واحجز خدمتك بكل سهولة وأمان.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 mb-10">
              <Button 
                size="lg" 
                className="rounded-full text-lg px-8 shadow-xl shadow-primary/25 hover:shadow-2xl hover:-translate-y-1 transition-all"
                onClick={() => document.getElementById('contact')?.scrollIntoView({ behavior: 'smooth' })}
              >
                ابدأ الآن
              </Button>
              <Button 
                size="lg" 
                variant="outline" 
                className="rounded-full text-lg px-8 border-2 hover:bg-primary/5 transition-all"
                onClick={() => document.getElementById('services')?.scrollIntoView({ behavior: 'smooth' })}
              >
                تعرف على المنصة
              </Button>
            </div>

            <div className="flex items-center gap-6 text-sm font-medium text-foreground/80">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5 text-primary" />
                <span>شركات موثوقة</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5 text-primary" />
                <span>أسعار شفافة</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-5 h-5 text-primary" />
                <span>حجز سريع</span>
              </div>
            </div>
          </motion.div>

          {/* Image */}
          <motion.div 
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="relative"
          >
            <div className="relative rounded-3xl overflow-hidden aspect-[4/3] shadow-2xl shadow-primary/10 border-8 border-white">
              <img 
                src="https://images.unsplash.com/photo-1556912173-3bb406ef7e77?w=800&q=80" 
                alt="منصة البريق للعمالة المنزلية" 
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
            </div>

            {/* Floating Card */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.8, duration: 0.5 }}
              className="absolute -bottom-8 -right-8 glass p-5 rounded-2xl flex items-center gap-4 shadow-xl"
            >
              <div className="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                <span className="text-2xl font-bold text-primary">4.9</span>
              </div>
              <div>
                <div className="flex gap-1 text-[#FFD700] mb-1">
                  {"★★★★★".split("").map((star, i) => (
                    <span key={i}>{star}</span>
                  ))}
                </div>
                <p className="text-sm font-bold text-foreground">تقييم المستخدمين</p>
                <p className="text-xs text-muted-foreground">+50 شركة مسجلة</p>
              </div>
            </motion.div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
