import { motion } from "framer-motion";
import { Building2, Users, Search, CheckCircle2 } from "lucide-react";

export function Services() {
  const services = [
    {
      icon: <Building2 className="w-8 h-8" />,
      title: "تسجيل الشركات",
      description: "نوفر للشركات منصة سهلة لتسجيل بياناتها وعرض العاملات المتوفرات لديها مع الأسعار والخدمات المقدمة.",
      image: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=500&q=80"
    },
    {
      icon: <Users className="w-8 h-8" />,
      title: "عرض العاملات",
      description: "كل شركة يمكنها عرض فريق عاملاتها المحترفات مع تفاصيل الخبرات والتخصصات والأسعار بشكل واضح.",
      image: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=500&q=80"
    },
    {
      icon: <Search className="w-8 h-8" />,
      title: "تصفح واختيار",
      description: "يمكن للعملاء تصفح جميع الشركات والعاملات المتاحة والمقارنة بينهم لاختيار الأنسب لاحتياجاتهم.",
      image: "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=500&q=80"
    },
    {
      icon: <CheckCircle2 className="w-8 h-8" />,
      title: "طلب الخدمة",
      description: "بعد التسجيل واختيار العاملة المناسبة، يمكن للعميل طلب الخدمة مباشرة وبسهولة عبر التطبيق.",
      image: "https://images.unsplash.com/photo-1563986768609-322da13575f3?w=500&q=80"
    }
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: { staggerChildren: 0.1 }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.5 } }
  };

  return (
    <section id="services" className="py-24 bg-secondary/50">
      <div className="container mx-auto px-4 md:px-6">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-primary/10 text-primary font-medium text-sm mb-4">
            <span>مميزات المنصة</span>
          </div>
          <h2 className="text-3xl md:text-4xl font-bold font-display mb-4">
            كيف يعمل تطبيق البريق؟
          </h2>
          <p className="text-muted-foreground text-lg">
            نربط العملاء بأفضل شركات العمالة المنزلية في المملكة، لنوفر لك تجربة حجز سهلة وآمنة وشفافة.
          </p>
        </div>

        <motion.div 
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-100px" }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8"
        >
          {services.map((service, idx) => (
            <motion.div 
              key={idx} 
              variants={itemVariants}
              className="bg-card rounded-2xl overflow-hidden shadow-lg shadow-black/5 border border-border/50 hover:shadow-xl hover:border-primary/30 group transition-all duration-300"
            >
              <div className="h-48 overflow-hidden relative">
                <img 
                  src={service.image} 
                  alt={service.title} 
                  className="absolute inset-0 w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                />
                <div className="absolute inset-0 bg-primary/20 group-hover:bg-transparent transition-colors z-10 mix-blend-multiply pointer-events-none" />
                <div className="absolute bottom-4 right-6 w-12 h-12 rounded-full bg-primary shadow-lg flex items-center justify-center text-primary-foreground z-20">
                  {service.icon}
                </div>
              </div>
              <div className="p-6">
                <h3 className="text-xl font-bold font-display mb-2 group-hover:text-primary transition-colors">
                  {service.title}
                </h3>
                <p className="text-muted-foreground text-sm leading-relaxed">
                  {service.description}
                </p>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
