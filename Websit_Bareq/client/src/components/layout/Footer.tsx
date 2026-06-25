import { Phone, Mail, MapPin, Facebook, Instagram, Twitter } from "lucide-react";
import { Logo } from "@/components/brand/Logo";

export function Footer() {
  return (
    <footer className="bg-foreground text-background pt-16 pb-8">
      <div className="container mx-auto px-4 md:px-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
          {/* Brand */}
          <div className="space-y-4">
            <Logo size="lg" variant="light" />
            <p className="text-muted-foreground/80 leading-relaxed">
              منصة رقمية تربط العملاء بشركات العمالة المنزلية المعتمدة. نوفر تجربة حجز سهلة وآمنة مع شفافية كاملة في الأسعار والخدمات.
            </p>
            <div className="flex gap-4 pt-2">
              <a href="#" className="w-10 h-10 rounded-full bg-white/10 flex items-center justify-center hover:bg-primary transition-colors">
                <Facebook className="w-5 h-5" />
              </a>
              <a href="#" className="w-10 h-10 rounded-full bg-white/10 flex items-center justify-center hover:bg-primary transition-colors">
                <Instagram className="w-5 h-5" />
              </a>
              <a href="#" className="w-10 h-10 rounded-full bg-white/10 flex items-center justify-center hover:bg-primary transition-colors">
                <Twitter className="w-5 h-5" />
              </a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-lg font-bold font-display mb-6 text-white relative inline-block after:absolute after:bottom-0 after:right-0 after:w-1/2 after:h-1 after:bg-primary after:rounded-full pb-2">
              روابط سريعة
            </h3>
            <ul className="space-y-3">
              <li><a href="#home" className="text-muted-foreground/80 hover:text-primary transition-colors">الرئيسية</a></li>
              <li><a href="#about" className="text-muted-foreground/80 hover:text-primary transition-colors">عن المنصة</a></li>
              <li><a href="#services" className="text-muted-foreground/80 hover:text-primary transition-colors">كيف يعمل</a></li>
              <li><a href="#contact" className="text-muted-foreground/80 hover:text-primary transition-colors">اتصل بنا</a></li>
            </ul>
          </div>

          {/* Services */}
          <div>
            <h3 className="text-lg font-bold font-display mb-6 text-white relative inline-block after:absolute after:bottom-0 after:right-0 after:w-1/2 after:h-1 after:bg-primary after:rounded-full pb-2">
              مميزات المنصة
            </h3>
            <ul className="space-y-3">
              <li className="text-muted-foreground/80">تسجيل الشركات</li>
              <li className="text-muted-foreground/80">عرض العاملات والأسعار</li>
              <li className="text-muted-foreground/80">تصفح ومقارنة</li>
              <li className="text-muted-foreground/80">حجز مباشر وآمن</li>
            </ul>
          </div>

          {/* Contact Info */}
          <div>
            <h3 className="text-lg font-bold font-display mb-6 text-white relative inline-block after:absolute after:bottom-0 after:right-0 after:w-1/2 after:h-1 after:bg-primary after:rounded-full pb-2">
              تواصل معنا
            </h3>
            <ul className="space-y-4">
              <li className="flex items-start gap-3">
                <MapPin className="w-5 h-5 text-primary shrink-0 mt-0.5" />
                <span className="text-muted-foreground/80">ليبيا - طرابلس - طريق المطار</span>
              </li>
              <li className="flex items-center gap-3">
                <Phone className="w-5 h-5 text-primary shrink-0" />
                <span className="text-muted-foreground/80" dir="ltr">0913433722</span>
              </li>
              <li className="flex items-center gap-3">
                <Mail className="w-5 h-5 text-primary shrink-0" />
                <span className="text-muted-foreground/80">info@albariq.com</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-white/10 pt-8 flex flex-col md:flex-row items-center justify-between text-sm text-muted-foreground/60">
          <p>© {new Date().getFullYear()} منصة البريق لخدمات العمالة المنزلية. جميع الحقوق محفوظة.</p>
          <div className="flex gap-4 mt-4 md:mt-0">
            <a href="#" className="hover:text-primary transition-colors">الشروط والأحكام</a>
            <a href="#" className="hover:text-primary transition-colors">سياسة الخصوصية</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
