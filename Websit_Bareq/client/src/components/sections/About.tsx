import { motion } from "framer-motion";
import { Shield, Clock, ThumbsUp, HeartHandshake } from "lucide-react";

export function About() {
  const features = [
    {
      icon: <Shield className="w-6 h-6" />,
      title: "شركات معتمدة",
      description: "نتعاون فقط مع الشركات المرخصة والموثوقة التي تلتزم بأعلى معايير الجودة والاحترافية."
    },
    {
      icon: <Clock className="w-6 h-6" />,
      title: "أسعار شفافة",
      description: "جميع الأسعار والخدمات معروضة بوضوح، مما يساعدك على اتخاذ القرار الأفضل لميزانيتك."
    },
    {
      icon: <ThumbsUp className="w-6 h-6" />,
      title: "خيارات متعددة",
      description: "تصفح عشرات الشركات ومئات العاملات المؤهلات واختر ما يناسب احتياجاتك بدقة."
    },
    {
      icon: <HeartHandshake className="w-6 h-6" />,
      title: "حجز مباشر",
      description: "سجل في المنصة، اختر العاملة المناسبة، واطلب الخدمة بكل سهولة من خلال التطبيق."
    }
  ];

  return (
    <section id="about" className="py-24 bg-white relative">
      <div className="container mx-auto px-4 md:px-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
          >
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-accent text-accent-foreground font-medium text-sm mb-6">
              <span>عن المنصة</span>
            </div>
            
            <h2 className="text-3xl md:text-4xl font-bold font-display mb-6">
              منصة متكاملة تربط العملاء بأفضل الشركات
            </h2>
            
            <p className="text-lg text-muted-foreground leading-relaxed mb-8">
              <strong className="text-primary font-bold">البريق</strong> هي منصة رقمية مبتكرة تجمع شركات العمالة المنزلية في مكان واحد. نساعد الشركات على عرض خدماتها وعاملاتها، بينما نوفر للعملاء تجربة سهلة للبحث والمقارنة والحجز.
              <br/><br/>
              من خلال منصتنا، يمكن للشركات إدارة بيانات عاملاتها وأسعارها، بينما يستطيع العملاء التسجيل واختيار العاملة المناسبة بكل ثقة وشفافية.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              {features.map((feature, idx) => (
                <div key={idx} className="flex gap-4">
                  <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center shrink-0 text-primary">
                    {feature.icon}
                  </div>
                  <div>
                    <h4 className="font-bold text-foreground mb-1">{feature.title}</h4>
                    <p className="text-sm text-muted-foreground">{feature.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="relative"
          >
            <img 
              src="https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=800&q=80" 
              alt="منصة البريق" 
              className="rounded-3xl shadow-2xl"
            />
            
            {/* Decorative element */}
            <div className="absolute -bottom-6 -left-6 w-32 h-32 rounded-full border-4 border-primary/20 -z-10" />
            <div className="absolute -top-6 -right-6 w-24 h-24 rounded-full bg-accent -z-10" />
          </motion.div>
        </div>
      </div>
    </section>
  );
}
