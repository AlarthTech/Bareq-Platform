import { Layout } from "@/components/layout";
import { useParams, useLocation } from "wouter";
import { useCleaner } from "@/hooks/use-cleaners";
import { useCreateBooking } from "@/hooks/use-bookings";
import { useUser } from "@/hooks/use-auth";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Star, MapPin, Clock, Calendar as CalendarIcon, Info } from "lucide-react";

export default function CleanerProfile() {
  const { id } = useParams<{ id: string }>();
  const { data: cleaner, isLoading, error } = useCleaner(Number(id));
  const { data: user } = useUser();
  const [, setLocation] = useLocation();
  const createBooking = useCreateBooking();

  const [bookingData, setBookingData] = useState({
    date: "",
    timeSlot: "",
    address: "",
    hours: 2, // Default to 2 hours
  });

  if (isLoading) return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 py-20 flex justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    </Layout>
  );

  if (error || !cleaner) return (
    <Layout>
      <div className="max-w-7xl mx-auto px-4 py-20 text-center">
        <h2 className="text-2xl font-bold mb-4">العاملة غير موجودة</h2>
        <Button onClick={() => setLocation("/")}>العودة للرئيسية</Button>
      </div>
    </Layout>
  );

  const displayRating = (cleaner.rating || 0) / 10;
  const totalPrice = cleaner.hourlyRate * bookingData.hours;

  const handleBooking = (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) {
      setLocation("/login");
      return;
    }
    
    if (user.role !== "customer") {
      alert("حسابات الشركات لا يمكنها الحجز");
      return;
    }

    createBooking.mutate({
      customerId: user.id,
      cleanerId: cleaner.id,
      date: bookingData.date,
      timeSlot: bookingData.timeSlot,
      address: bookingData.address,
      totalPrice: totalPrice,
      status: "pending"
    });
  };

  return (
    <Layout>
      <div className="bg-primary/5 border-b border-border/50 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row gap-8 items-start">
            <div className="w-full md:w-1/3 aspect-square max-w-sm rounded-3xl overflow-hidden shadow-xl border-4 border-background bg-muted">
              <img 
                src={cleaner.imageUrl || "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80"} 
                alt={cleaner.name}
                className="w-full h-full object-cover"
              />
            </div>
            
            <div className="flex-1 pt-4">
              <h1 className="text-4xl font-display font-black text-foreground mb-4">{cleaner.name}</h1>
              
              <div className="flex flex-wrap gap-4 mb-6">
                <div className="flex items-center gap-1.5 bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-500 px-3 py-1.5 rounded-lg font-bold">
                  <Star className="w-5 h-5 fill-current" />
                  <span>{displayRating.toFixed(1)} / 5.0</span>
                </div>
                <div className="flex items-center gap-1.5 bg-card border px-3 py-1.5 rounded-lg font-medium">
                  <Clock className="w-5 h-5 text-primary" />
                  <span>{cleaner.hourlyRate} ريال / ساعة</span>
                </div>
              </div>

              <div className="bg-card p-6 rounded-2xl border shadow-sm">
                <h3 className="font-bold text-lg mb-2 flex items-center gap-2">
                  <Info className="w-5 h-5 text-primary" /> نبذة تعريفية
                </h3>
                <p className="text-muted-foreground leading-relaxed">
                  {cleaner.bio || "لا يوجد نبذة تعريفية متوفرة حالياً."}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12">
          {/* Booking Form Area */}
          <div className="lg:col-span-8">
            <div className="bg-card rounded-3xl p-8 border shadow-premium">
              <h2 className="text-2xl font-display font-bold mb-6 flex items-center gap-3">
                <CalendarIcon className="w-7 h-7 text-primary" />
                حجز موعد جديد
              </h2>
              
              <form onSubmit={handleBooking} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-3">
                    <Label className="text-base font-bold">تاريخ الحجز</Label>
                    <Input 
                      type="date" 
                      required
                      min={new Date().toISOString().split('T')[0]}
                      value={bookingData.date}
                      onChange={e => setBookingData({...bookingData, date: e.target.value})}
                      className="h-14 rounded-xl text-lg"
                    />
                  </div>
                  
                  <div className="space-y-3">
                    <Label className="text-base font-bold">وقت البداية المتوقع</Label>
                    <Input 
                      type="time" 
                      required
                      value={bookingData.timeSlot}
                      onChange={e => setBookingData({...bookingData, timeSlot: e.target.value})}
                      className="h-14 rounded-xl text-lg"
                    />
                  </div>
                </div>

                <div className="space-y-3">
                  <Label className="text-base font-bold flex items-center justify-between">
                    <span>عدد الساعات المطلوبة</span>
                    <span className="text-primary font-black text-xl">{bookingData.hours} ساعات</span>
                  </Label>
                  <input 
                    type="range" 
                    min="1" max="10" step="1"
                    value={bookingData.hours}
                    onChange={e => setBookingData({...bookingData, hours: parseInt(e.target.value)})}
                    className="w-full h-3 bg-muted rounded-lg appearance-none cursor-pointer accent-primary"
                  />
                  <div className="flex justify-between text-xs text-muted-foreground">
                    <span>1 ساعة</span>
                    <span>10 ساعات</span>
                  </div>
                </div>

                <div className="space-y-3">
                  <Label className="text-base font-bold">العنوان التفصيلي</Label>
                  <Textarea 
                    required
                    placeholder="الحي، الشارع، رقم المبنى..."
                    value={bookingData.address}
                    onChange={e => setBookingData({...bookingData, address: e.target.value})}
                    className="min-h-[120px] rounded-xl text-base p-4 resize-none"
                  />
                </div>
                
                {/* Summary Box */}
                <div className="bg-muted/50 p-6 rounded-2xl border mt-8 flex flex-col md:flex-row justify-between items-center gap-4">
                  <div>
                    <p className="text-sm font-medium text-muted-foreground mb-1">التكلفة الإجمالية المقدرة</p>
                    <p className="text-3xl font-black text-foreground">{totalPrice} ريال</p>
                  </div>
                  <Button 
                    type="submit" 
                    size="lg" 
                    className="w-full md:w-auto h-14 px-10 text-lg rounded-xl"
                    disabled={createBooking.isPending}
                  >
                    {createBooking.isPending ? "جاري التأكيد..." : "تأكيد الحجز الآن"}
                  </Button>
                </div>
                {!user && (
                  <p className="text-sm text-destructive text-center font-medium">يجب تسجيل الدخول كعميل لإتمام الحجز</p>
                )}
              </form>
            </div>
          </div>
          
          {/* Side Info */}
          <div className="lg:col-span-4 space-y-6">
            <div className="bg-primary/5 p-6 rounded-3xl border border-primary/20">
              <h3 className="font-bold text-lg mb-4 text-primary">لماذا تحجز عبر البريق؟</h3>
              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <div className="bg-background rounded-full p-1 mt-0.5 shadow-sm text-primary">✓</div>
                  <span className="text-sm font-medium">دفع آمن ومضمون بعد إتمام الخدمة.</span>
                </li>
                <li className="flex items-start gap-3">
                  <div className="bg-background rounded-full p-1 mt-0.5 shadow-sm text-primary">✓</div>
                  <span className="text-sm font-medium">عمالة مدربة ومؤهلة تأهيلاً عالياً.</span>
                </li>
                <li className="flex items-start gap-3">
                  <div className="bg-background rounded-full p-1 mt-0.5 shadow-sm text-primary">✓</div>
                  <span className="text-sm font-medium">دعم فني متواجد على مدار الساعة.</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}
